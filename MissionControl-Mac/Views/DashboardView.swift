import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: AppStore
    @State private var quickPrompt: String = ""

    private let statColumns = [
        GridItem(.flexible(minimum: 220), spacing: MCSpacing.md),
        GridItem(.flexible(minimum: 220), spacing: MCSpacing.md),
        GridItem(.flexible(minimum: 220), spacing: MCSpacing.md),
        GridItem(.flexible(minimum: 220), spacing: MCSpacing.md)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: MCSpacing.lg) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Dashboard")
                    .font(MCFont.pageTitle)
                    .foregroundStyle(MCColor.textPrimary)
                Text("Operational view of your OpenClaw gateway, sessions, and activity")
                    .font(MCFont.pageSubtitle)
                    .foregroundStyle(MCColor.textSecondary)
            }

            LazyVGrid(columns: statColumns, spacing: MCSpacing.md) {
                statCard(
                    title: "Connection",
                    value: store.isConnected ? "Connected" : "Disconnected",
                    hint: store.connectionErrorDetail ?? (store.normalizedBaseURL.isEmpty ? "Set gateway URL in Settings" : store.normalizedBaseURL),
                    dot: store.isConnected ? MCColor.green : MCColor.red
                )

                statCard(
                    title: "Model",
                    value: store.effectiveModel,
                    hint: "Gateway/default model",
                    dot: MCColor.accent
                )

                statCard(
                    title: "Active Sessions",
                    value: "\(store.effectiveActiveSessions)",
                    hint: store.gatewaySessions.isEmpty ? "No gateway sessions yet" : "Live from gateway",
                    dot: MCColor.orange
                )

                statCard(
                    title: "Last latency",
                    value: store.lastResponseLatencyMs.map { "\($0) ms" } ?? "—",
                    hint: "Most recent response time",
                    dot: MCColor.green
                )
            }

            quickStatsCard

            HStack(alignment: .top, spacing: MCSpacing.md) {
                operationsCard
                activeSessionCard
            }

            eventsCard
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var quickStatsCard: some View {
        MCCard {
            HStack(spacing: MCSpacing.lg) {
                statChip(title: "Requests Today", value: "\(store.requestsToday)", tint: MCColor.accent)
                statChip(title: "Errors Today", value: "\(store.errorsToday)", tint: MCColor.red)
                statChip(title: "Avg Latency", value: store.averageLatencyMs.map { "\($0) ms" } ?? "—", tint: MCColor.orange)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var operationsCard: some View {
        MCCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Gateway Operations")
                    .font(MCFont.sectionTitle)
                    .foregroundStyle(MCColor.textPrimary)

                TextField("Send a quick message to selected session…", text: $quickPrompt, axis: .vertical)
                    .lineLimit(1...4)
                    .textFieldStyle(.roundedBorder)

                HStack(spacing: 10) {
                    Button("Send") {
                        let payload = quickPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !payload.isEmpty else { return }
                        quickPrompt = ""
                        Task { await store.sendMessage(payload) }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(quickPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.isSending)

                    Button("Health Check") {
                        Task { await store.runHealthCheck() }
                    }
                    .buttonStyle(.bordered)

                    Button(store.isRefreshingGatewayData ? "Refreshing…" : "Refresh Gateway") {
                        Task { await store.refreshGatewayData() }
                    }
                    .buttonStyle(.bordered)
                    .disabled(store.isRefreshingGatewayData)

                    Button("New Session") {
                        store.addSession()
                    }
                    .buttonStyle(.bordered)
                }

                if store.taskProgress.state == .running {
                    VStack(alignment: .leading, spacing: 6) {
                        ProgressView(value: store.taskProgress.percent)
                        Text(store.taskProgress.detail)
                            .font(MCFont.caption)
                            .foregroundStyle(MCColor.textSecondary)
                    }
                } else {
                    Text("Use this panel as your control center for fast checks and test prompts.")
                        .font(MCFont.caption)
                        .foregroundStyle(MCColor.textSecondary)
                }

                if let gatewaySyncError = store.gatewaySyncError, !gatewaySyncError.isEmpty {
                    Label(gatewaySyncError, systemImage: "exclamationmark.triangle.fill")
                        .font(MCFont.caption)
                        .foregroundStyle(MCColor.orange)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 220, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity)
    }

    private var activeSessionCard: some View {
        MCCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Active Session")
                    .font(MCFont.sectionTitle)
                    .foregroundStyle(MCColor.textPrimary)

                if let session = store.selectedSession {
                    Picker("Session", selection: $store.selectedSessionID) {
                        ForEach(store.sessions) { session in
                            Text(session.title).tag(Optional(session.id))
                        }
                    }
                    .labelsHidden()

                    Text(session.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(MCColor.textPrimary)

                    Text(session.sessionKey)
                        .font(MCFont.caption)
                        .foregroundStyle(MCColor.textSecondary)
                        .textSelection(.enabled)

                    Divider().overlay(MCColor.divider)

                    if session.messages.isEmpty {
                        Text("No messages yet. Use Gateway Operations to send a prompt.")
                            .font(MCFont.body)
                            .foregroundStyle(MCColor.textSecondary)
                    } else {
                        ForEach(Array(session.messages.suffix(3))) { message in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(message.role.uppercased())
                                    .font(MCFont.tiny)
                                    .foregroundStyle(MCColor.textTertiary)
                                Text(message.text)
                                    .font(MCFont.body)
                                    .foregroundStyle(MCColor.textPrimary)
                                    .lineLimit(2)
                            }
                        }
                    }
                } else {
                    Text("No session selected")
                        .font(MCFont.body)
                        .foregroundStyle(MCColor.textSecondary)

                    Button("Create Session") {
                        store.addSession()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 220, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity)
    }

    private var eventsCard: some View {
        MCCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Recent Events")
                        .font(MCFont.sectionTitle)
                        .foregroundStyle(MCColor.textPrimary)
                    Spacer()
                    Text("\(min(store.events.count, 10)) shown")
                        .font(MCFont.caption)
                        .foregroundStyle(MCColor.textSecondary)
                }

                if store.events.isEmpty {
                    Text("No events yet")
                        .font(MCFont.body)
                        .foregroundStyle(MCColor.textSecondary)
                } else {
                    ForEach(Array(store.events.prefix(10))) { event in
                        HStack(alignment: .top, spacing: 10) {
                            StatusDot(color: color(for: event.level), size: 7)
                                .padding(.top, 4)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.message)
                                    .font(MCFont.body)
                                    .foregroundStyle(MCColor.textPrimary)
                                Text(event.ts.formatted(date: .omitted, time: .shortened))
                                    .font(MCFont.caption)
                                    .foregroundStyle(MCColor.textSecondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func statChip(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(MCFont.tiny)
                .foregroundStyle(MCColor.textTertiary)
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(tint)
        }
        .padding(.vertical, 2)
    }

    private func statCard(title: String, value: String, hint: String, dot: Color) -> some View {
        MCCard(padding: MCSpacing.md) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    StatusDot(color: dot, size: 7)
                    Text(title.uppercased())
                        .font(MCFont.tiny)
                        .foregroundStyle(MCColor.textTertiary)
                }

                Text(value)
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(MCColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(hint)
                    .font(MCFont.caption)
                    .foregroundStyle(MCColor.textSecondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity)
    }

    private func color(for level: EventLevel) -> Color {
        switch level {
        case .info: return MCColor.accent
        case .warning: return MCColor.orange
        case .error: return MCColor.red
        }
    }
}
