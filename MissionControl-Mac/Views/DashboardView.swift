import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        VStack(alignment: .leading, spacing: MCSpacing.lg) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Dashboard")
                    .font(MCFont.pageTitle)
                    .foregroundStyle(MCColor.textPrimary)
                Text("Live status for your OpenClaw workspace")
                    .font(MCFont.pageSubtitle)
                    .foregroundStyle(MCColor.textSecondary)
            }

            HStack(spacing: MCSpacing.md) {
                statCard(
                    title: "Connection",
                    value: store.isConnected ? "Connected" : "Disconnected",
                    hint: store.normalizedBaseURL.isEmpty ? "Set gateway URL in Settings" : store.normalizedBaseURL,
                    dot: store.isConnected ? MCColor.green : MCColor.red
                )

                statCard(
                    title: "Model",
                    value: store.lastModelUsed ?? store.profile.model,
                    hint: "Current chat model",
                    dot: MCColor.accent
                )

                statCard(
                    title: "Sessions",
                    value: "\(store.sessions.count)",
                    hint: "Local session history",
                    dot: MCColor.orange
                )

                statCard(
                    title: "Last latency",
                    value: store.lastResponseLatencyMs.map { "\($0) ms" } ?? "—",
                    hint: "Most recent response",
                    dot: MCColor.green
                )
            }

            HStack(alignment: .top, spacing: MCSpacing.md) {
                MCCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent events")
                            .font(MCFont.sectionTitle)
                            .foregroundStyle(MCColor.textPrimary)

                        if store.events.isEmpty {
                            Text("No events yet")
                                .font(MCFont.body)
                                .foregroundStyle(MCColor.textSecondary)
                        } else {
                            ForEach(Array(store.events.prefix(8))) { event in
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
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                MCCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick actions")
                            .font(MCFont.sectionTitle)
                            .foregroundStyle(MCColor.textPrimary)

                        Button("Run Health Check") {
                            Task { await store.runHealthCheck() }
                        }
                        .buttonStyle(.borderedProminent)

                        Button("New Chat Session") {
                            store.addSession()
                            store.selectedSection = .agents
                        }
                        .buttonStyle(.bordered)

                        Button("Open Settings") {
                            store.selectedSection = .settings
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(width: 260, alignment: .leading)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(MCSpacing.lg)
    }

    private func statCard(title: String, value: String, hint: String, dot: Color) -> some View {
        MCCard(padding: MCSpacing.md) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    StatusDot(color: dot, size: 7)
                    Text(title.uppercased())
                        .font(MCFont.tiny)
                        .foregroundStyle(MCColor.textTertiary)
                }
                Text(value)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(MCColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(hint)
                    .font(MCFont.caption)
                    .foregroundStyle(MCColor.textSecondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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
