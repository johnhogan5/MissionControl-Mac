import Foundation

enum SidebarSection: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case journal = "Journal"
    case documents = "Documents"
    case agents = "Agents"
    case intelligence = "Intelligence"
    case weeklyRecaps = "Weekly Recaps"
    case clients = "Clients"
    case logs = "Logs"
    case cronJobs = "Cron Jobs"
    case apiUsage = "API Usage"
    case workshop = "Workshop"
    case projects = "Projects"
    case settings = "Settings"

    var id: String { rawValue }
}

struct ConnectionProfile: Codable, Equatable {
    var name: String = "Default"
    var baseURL: String = ""
    var defaultSessionKey: String = "agent:main:main"
    var model: String = "openai-codex/gpt-5.3-codex"
    var healthPollingSeconds: Int = 20
}

struct AppEvent: Identifiable, Codable {
    let id: UUID
    let ts: Date
    let level: EventLevel
    let message: String

    init(id: UUID = UUID(), ts: Date = Date(), level: EventLevel, message: String) {
        self.id = id
        self.ts = ts
        self.level = level
        self.message = message
    }
}

enum EventLevel: String, Codable {
    case info, warning, error
}

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let role: String
    var text: String
    let ts: Date

    init(id: UUID = UUID(), role: String, text: String, ts: Date = Date()) {
        self.id = id
        self.role = role
        self.text = text
        self.ts = ts
    }
}

struct LocalSession: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var sessionKey: String
    var messages: [ChatMessage] = []
    var updatedAt: Date = Date()
}

struct TaskStep: Identifiable, Codable {
    let id: UUID
    var title: String
    var isDone: Bool

    init(id: UUID = UUID(), title: String, isDone: Bool = false) {
        self.id = id
        self.title = title
        self.isDone = isDone
    }
}

enum TaskState: String, Codable {
    case idle, running, completed, failed
}

struct TaskProgress: Codable {
    var state: TaskState = .idle
    var taskTitle: String = "Idle"
    var detail: String = "No active task"
    var percent: Double = 0
    var startedAt: Date?
    var updatedAt: Date = Date()
    var steps: [TaskStep] = []
}

struct JournalEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var body: String
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}

struct CronJobSummary: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var schedule: String
    var enabled: Bool
    var lastRun: String
}
