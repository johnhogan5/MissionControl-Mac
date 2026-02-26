import SwiftUI

struct APIUsageView: View {
    @EnvironmentObject private var store: AppStore

    private var totalMessages: Int {
        store.sessions.reduce(0) { $0 + $1.messages.count }
    }

    private var assistantMessages: Int {
        store.sessions.reduce(0) { $0 + $1.messages.filter { $0.role == "assistant" }.count }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MCSpacing.md) {
            Text("API Usage")
                .font(.largeTitle.weight(.semibold))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: MCSpacing.sm) {
                MetricCard(title: "Total Messages", value: "\(totalMessages)", hint: "Local history", tint: .blue)
                MetricCard(title: "Assistant Replies", value: "\(assistantMessages)", hint: "Responses", tint: .green)
                MetricCard(title: "Last Latency", value: store.lastResponseLatencyMs.map { "\($0) ms" } ?? "—", hint: "Latest call", tint: .orange)
            }

            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cost Strategy")
                        .font(.headline)
                    Text("Default to Codex, fallback to Sonnet, escalate to Opus for high-risk or critical tasks.")
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
    }
}
