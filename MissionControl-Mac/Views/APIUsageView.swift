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
                .font(MCFont.pageTitle)
                .foregroundStyle(MCColor.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: MCSpacing.sm) {
                MetricCard(title: "Requests Today", value: "\(store.requestsToday)", hint: "User prompts today", tint: .blue)
                MetricCard(title: "Errors Today", value: "\(store.errorsToday)", hint: "Gateway/app errors", tint: .red)
                MetricCard(title: "Avg Latency", value: store.averageLatencyMs.map { "\($0) ms" } ?? "—", hint: "Rolling local average", tint: .orange)
                MetricCard(title: "Total Messages", value: "\(totalMessages)", hint: "Local history", tint: .purple)
                MetricCard(title: "Assistant Replies", value: "\(assistantMessages)", hint: "Responses", tint: .green)
                MetricCard(title: "Last Latency", value: store.lastResponseLatencyMs.map { "\($0) ms" } ?? "—", hint: "Most recent call", tint: .mint)
            }

            MCCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Interpretation")
                        .font(MCFont.cardTitle)
                        .foregroundStyle(MCColor.textPrimary)
                    Text("Use Requests Today + Avg Latency to watch throughput, and Errors Today to catch regressions after deploys.")
                        .font(MCFont.body)
                        .foregroundStyle(MCColor.textSecondary)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
