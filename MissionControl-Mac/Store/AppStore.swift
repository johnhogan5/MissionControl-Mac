import Foundation
import SwiftUI
import Combine

@MainActor
final class AppStore: ObservableObject {
    // Navigation/UI
    @Published var selectedSection: SidebarSection = .dashboard

    // Config/Auth
    @Published var profile: ConnectionProfile
    @Published var token: String
    @Published var settingsValidationErrors: [String] = []

    // Runtime status
    @Published var isConnected: Bool = false
    @Published var connectionLabel: String = "Unknown"
    @Published var isSending: Bool = false
    @Published var taskProgress: TaskProgress = TaskProgress()
    @Published var taskHistory: [TaskProgress] = []
    @Published var lastResponseLatencyMs: Int?
    @Published var latencySamples: [Int]
    @Published var lastModelUsed: String?
    @Published var connectionErrorDetail: String?
    @Published var gatewaySessions: [GatewaySessionSummary] = []
    @Published var gatewayStatus: GatewayStatusSnapshot?
    @Published var isRefreshingGatewayData: Bool = false
    @Published var gatewaySyncError: String?

    // Data
    @Published var sessions: [LocalSession]
    @Published var selectedSessionID: UUID?
    @Published var events: [AppEvent]
    @Published var journalEntries: [JournalEntry]
    @Published var cronJobs: [CronJobSummary]

    private let tokenKey = "missioncontrol.mac.gateway.token"
    private let poller = HealthPoller()

    init() {
        self.profile = Persistence.loadProfile()
        self.token = Keychain.load(key: tokenKey)
        self.sessions = Persistence.loadSessions()
        self.events = Persistence.loadEvents()
        self.journalEntries = Persistence.loadJournal()
        self.cronJobs = Persistence.loadCronJobs()
        self.latencySamples = Persistence.loadLatencySamples()
        self.selectedSessionID = self.sessions.first?.id

        addEvent(.info, "Mission Control initialized")
        startHealthPolling()
        Task {
            await runHealthCheck()
            await refreshGatewayData()
        }
    }

    var normalizedBaseURL: String {
        profile.baseURL
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    var selectedSession: LocalSession? {
        get { sessions.first(where: { $0.id == selectedSessionID }) }
        set {
            guard let newValue = newValue,
                  let idx = sessions.firstIndex(where: { $0.id == newValue.id }) else { return }
            sessions[idx] = newValue
            sessions[idx].updatedAt = Date()
            Persistence.saveSessions(sessions)
        }
    }

    var requestsToday: Int {
        sessions.reduce(0) { partial, session in
            partial + session.messages.filter {
                $0.role == "user" && Calendar.current.isDateInToday($0.ts)
            }.count
        }
    }

    var errorsToday: Int {
        events.filter {
            $0.level == .error && Calendar.current.isDateInToday($0.ts)
        }.count
    }

    var averageLatencyMs: Int? {
        guard !latencySamples.isEmpty else { return nil }
        return Int(Double(latencySamples.reduce(0, +)) / Double(latencySamples.count))
    }

    var effectiveActiveSessions: Int {
        gatewayStatus?.activeSessions ?? gatewaySessions.count
    }

    var effectiveModel: String {
        gatewayStatus?.model ?? lastModelUsed ?? profile.model
    }

    func saveProfile() {
        settingsValidationErrors = validateSettings()
        guard settingsValidationErrors.isEmpty else {
            connectionErrorDetail = settingsValidationErrors.first
            addEvent(.error, "Profile validation failed")
            return
        }

        Persistence.saveProfile(profile)
        Keychain.save(token, key: tokenKey)
        addEvent(.info, "Profile saved")
        startHealthPolling()
        Task {
            await runHealthCheck()
            await refreshGatewayData()
        }
    }

    func addSession() {
        let new = LocalSession(title: "Session \(sessions.count + 1)", sessionKey: profile.defaultSessionKey)
        sessions.insert(new, at: 0)
        selectedSessionID = new.id
        Persistence.saveSessions(sessions)
        addEvent(.info, "Created new local session")
    }

    func addJournalEntry(title: String, body: String) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        let entry = JournalEntry(title: trimmedTitle, body: body)
        journalEntries.insert(entry, at: 0)
        Persistence.saveJournal(journalEntries)
        addEvent(.info, "Journal entry added")
    }

    func deleteJournalEntry(_ id: UUID) {
        journalEntries.removeAll { $0.id == id }
        Persistence.saveJournal(journalEntries)
        addEvent(.warning, "Journal entry deleted")
    }

    func toggleCronJob(_ id: UUID) {
        guard let idx = cronJobs.firstIndex(where: { $0.id == id }) else { return }
        cronJobs[idx].enabled.toggle()
        Persistence.saveCronJobs(cronJobs)
        addEvent(.info, "Cron job \(cronJobs[idx].name) \(cronJobs[idx].enabled ? "enabled" : "disabled")")
    }

    func renameSession(_ id: UUID, title: String) {
        guard let idx = sessions.firstIndex(where: { $0.id == id }) else { return }
        sessions[idx].title = title
        sessions[idx].updatedAt = Date()
        Persistence.saveSessions(sessions)
    }

    func deleteSession(_ id: UUID) {
        sessions.removeAll { $0.id == id }
        if selectedSessionID == id {
            selectedSessionID = sessions.first?.id
        }
        Persistence.saveSessions(sessions)
        addEvent(.warning, "Deleted local session")
    }

    func clearEvents() {
        events = []
        Persistence.saveEvents([])
    }

    func sendMessage(_ text: String) async {
        let payload = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !payload.isEmpty else { return }

        beginTask(
            "Process chat request",
            detail: "Validating request",
            steps: [
                "Validate local configuration",
                "Send request to gateway",
                "Stream model response",
                "Persist response to session"
            ]
        )

        settingsValidationErrors = validateSettings(requireToken: true)
        guard settingsValidationErrors.isEmpty else {
            failTask(settingsValidationErrors.first ?? "Invalid settings")
            addEvent(.error, "Settings invalid")
            return
        }

        guard let sessionID = selectedSessionID,
              let idx = sessions.firstIndex(where: { $0.id == sessionID }) else {
            failTask("No active session selected")
            addEvent(.error, "No active session selected")
            return
        }

        advanceTask(stepIndex: 0, detail: "Configuration verified", percent: 0.2)

        sessions[idx].messages.append(ChatMessage(role: "user", text: payload))
        sessions[idx].updatedAt = Date()
        Persistence.saveSessions(sessions)

        isSending = true
        defer { isSending = false }

        do {
            let started = Date()
            advanceTask(stepIndex: 1, detail: "Sending request to OpenClaw gateway", percent: 0.4)

            sessions[idx].messages.append(ChatMessage(role: "assistant", text: ""))
            let assistantMessageIndex = sessions[idx].messages.count - 1
            Persistence.saveSessions(sessions)

            var streamedText = ""
            var chunkCount = 0

            for try await chunk in OpenClawClient.shared.streamResponse(
                baseURL: normalizedBaseURL,
                token: token,
                sessionKey: sessions[idx].sessionKey,
                model: profile.model,
                input: payload
            ) {
                chunkCount += 1
                streamedText += chunk
                sessions[idx].messages[assistantMessageIndex].text = streamedText
                sessions[idx].updatedAt = Date()
                if chunkCount % 4 == 0 {
                    Persistence.saveSessions(sessions)
                }
                advanceTask(stepIndex: 2, detail: "Streaming response…", percent: min(0.85, 0.45 + Double(chunkCount) * 0.015))
            }

            let finalText = streamedText.trimmingCharacters(in: .whitespacesAndNewlines)
            sessions[idx].messages[assistantMessageIndex].text = finalText.isEmpty ? "(No response text)" : finalText
            sessions[idx].updatedAt = Date()
            Persistence.saveSessions(sessions)

            let latencyMs = Int(Date().timeIntervalSince(started) * 1000)
            lastResponseLatencyMs = latencyMs
            latencySamples.append(latencyMs)
            if latencySamples.count > 500 { latencySamples = Array(latencySamples.suffix(500)) }
            Persistence.saveLatencySamples(latencySamples)
            lastModelUsed = profile.model

            advanceTask(stepIndex: 3, detail: "Session updated", percent: 0.95)
            completeTask("Request completed successfully")
            addEvent(.info, "Response received (streaming)")
            Task { await refreshGatewayData() }
        } catch {
            sessions[idx].messages.append(ChatMessage(role: "assistant", text: "Error: \(error.localizedDescription)"))
            sessions[idx].updatedAt = Date()
            Persistence.saveSessions(sessions)
            failTask("Request failed: \(error.localizedDescription)")
            addEvent(.error, "Send failed: \(error.localizedDescription)")
        }
    }

    func refreshGatewayData() async {
        settingsValidationErrors = validateSettings(requireToken: true)
        guard settingsValidationErrors.isEmpty else {
            gatewaySyncError = settingsValidationErrors.first
            gatewaySessions = []
            gatewayStatus = nil
            return
        }

        isRefreshingGatewayData = true
        defer { isRefreshingGatewayData = false }

        do {
            async let statusTask = OpenClawClient.shared.fetchGatewayStatus(baseURL: normalizedBaseURL, token: token)
            async let sessionsTask = OpenClawClient.shared.fetchGatewaySessions(baseURL: normalizedBaseURL, token: token)

            let (status, sessions) = try await (statusTask, sessionsTask)
            gatewayStatus = status
            gatewaySessions = sessions
            gatewaySyncError = nil
            addEvent(.info, "Gateway data synced")
        } catch {
            gatewaySyncError = error.localizedDescription
            addEvent(.warning, "Gateway sync failed: \(error.localizedDescription)")
        }
    }

    func runHealthCheck() async {
        beginTask(
            "Run health check",
            detail: "Validating health-check prerequisites",
            steps: [
                "Validate connection profile",
                "Query gateway /health",
                "Update runtime status"
            ]
        )

        settingsValidationErrors = validateSettings(requireToken: true)
        guard settingsValidationErrors.isEmpty else {
            isConnected = false
            connectionLabel = "Not configured"
            connectionErrorDetail = settingsValidationErrors.first
            failTask("Missing or invalid gateway settings")
            return
        }

        advanceTask(stepIndex: 0, detail: "Profile validated", percent: 0.25)

        do {
            let ok = try await OpenClawClient.shared.health(baseURL: normalizedBaseURL, token: token)
            advanceTask(stepIndex: 1, detail: "Health endpoint responded", percent: 0.7)
            isConnected = ok
            connectionLabel = ok ? "Connected" : "Unhealthy"
            connectionErrorDetail = ok ? nil : "Gateway responded but reported unhealthy."
            if ok {
                addEvent(.info, "Health check OK")
                completeTask("Gateway healthy")
            } else {
                addEvent(.warning, "Health check unhealthy")
                failTask("Gateway reported unhealthy")
            }
            advanceTask(stepIndex: 2, detail: "Runtime status updated", percent: 0.9)
        } catch {
            isConnected = false
            connectionLabel = "Disconnected"
            connectionErrorDetail = "If using VPS loopback, ensure SSH tunnel is active: ssh -N -L 18789:127.0.0.1:18789 root@187.77.218.90"
            addEvent(.error, "Health check failed: \(error.localizedDescription)")
            failTask("Health check failed: \(error.localizedDescription)")
        }
    }

    func startHealthPolling() {
        poller.start(intervalSeconds: profile.healthPollingSeconds) { [weak self] in
            await self?.runHealthCheck()
        }
    }

    private func beginTask(_ title: String, detail: String, steps: [String]) {
        taskProgress = TaskProgress(
            state: .running,
            taskTitle: title,
            detail: detail,
            percent: 0.05,
            startedAt: Date(),
            updatedAt: Date(),
            steps: steps.map { TaskStep(title: $0) }
        )
    }

    private func advanceTask(stepIndex: Int, detail: String, percent: Double) {
        guard taskProgress.state == .running else { return }
        taskProgress.detail = detail
        taskProgress.percent = min(max(percent, 0), 0.99)
        taskProgress.updatedAt = Date()
        if taskProgress.steps.indices.contains(stepIndex) {
            taskProgress.steps[stepIndex].isDone = true
        }
    }

    private func completeTask(_ detail: String) {
        taskProgress.state = .completed
        taskProgress.detail = detail
        taskProgress.percent = 1.0
        taskProgress.updatedAt = Date()
        for idx in taskProgress.steps.indices {
            taskProgress.steps[idx].isDone = true
        }
        taskHistory.insert(taskProgress, at: 0)
        if taskHistory.count > 100 { taskHistory = Array(taskHistory.prefix(100)) }
    }

    private func failTask(_ detail: String) {
        taskProgress.state = .failed
        taskProgress.detail = detail
        taskProgress.updatedAt = Date()
        taskHistory.insert(taskProgress, at: 0)
        if taskHistory.count > 100 { taskHistory = Array(taskHistory.prefix(100)) }
    }

    func addEvent(_ level: EventLevel, _ message: String) {
        events.insert(AppEvent(level: level, message: message), at: 0)
        if events.count > 500 { events = Array(events.prefix(500)) }
        Persistence.saveEvents(events)
    }

    private func validateSettings(requireToken: Bool = false) -> [String] {
        var issues: [String] = []

        if normalizedBaseURL.isEmpty {
            issues.append("Gateway URL is required.")
        } else if URL(string: normalizedBaseURL) == nil || !(normalizedBaseURL.hasPrefix("http://") || normalizedBaseURL.hasPrefix("https://")) {
            issues.append("Gateway URL must start with http:// or https://")
        }

        if requireToken && token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append("Gateway token is required.")
        }

        if profile.model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append("Default model cannot be empty.")
        }

        if profile.defaultSessionKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append("Default session key cannot be empty.")
        }

        return issues
    }
}
