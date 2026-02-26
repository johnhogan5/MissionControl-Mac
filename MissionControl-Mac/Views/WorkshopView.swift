import SwiftUI

struct WorkshopView: View {
    @EnvironmentObject private var store: AppStore

    private let queued = [
        "Client Sentiment Tracking",
        "Memory Refactor",
        "Policy Recap Builder",
        "Weekly Digest Generator"
    ]

    private let completed = [
        "Security baseline applied",
        "Model policy routing saved",
        "Cloudflare tunnel disabled"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MCSpacing.md) {
                Text("Mission Control Workshop")
                    .font(.largeTitle.weight(.semibold))

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: MCSpacing.sm) {
                    MetricCard(title: "Queued", value: "\(queued.count)", hint: "Ready", tint: .orange)
                    MetricCard(title: "Active", value: store.taskProgress.state == .running ? "1" : "0", hint: "Live", tint: .blue)
                    MetricCard(title: "Completed", value: "\(completed.count)", hint: "Today", tint: .green)
                    MetricCard(title: "Errors", value: "0", hint: "Stable", tint: .red)
                }

                HStack(alignment: .top, spacing: MCSpacing.sm) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Queued Tasks")
                                .font(.headline)
                            ForEach(queued, id: \.self) { item in
                                HStack {
                                    Text(item)
                                    Spacer()
                                    Button("Start") {}
                                        .buttonStyle(.bordered)
                                }
                            }
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Active")
                                .font(.headline)
                            Text(store.taskProgress.taskTitle)
                                .font(.subheadline.weight(.semibold))
                            Text(store.taskProgress.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            ProgressView(value: store.taskProgress.percent)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Completed")
                                .font(.headline)
                            ForEach(completed, id: \.self) { item in
                                Label(item, systemImage: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
            }
        }
    }
}
