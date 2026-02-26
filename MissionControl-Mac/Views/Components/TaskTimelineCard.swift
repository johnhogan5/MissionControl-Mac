import SwiftUI

struct TaskTimelineCard: View {
    let items: [TaskProgress]

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: MCSpacing.sm) {
                Text("Recent Activity")
                    .font(.headline)

                if items.isEmpty {
                    Text("No recent tasks")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                } else {
                    ForEach(Array(items.prefix(6).enumerated()), id: \.offset) { _, item in
                        HStack(alignment: .top, spacing: MCSpacing.xs) {
                            Circle()
                                .fill(color(for: item.state))
                                .frame(width: 8, height: 8)
                                .padding(.top, 6)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.taskTitle)
                                    .font(.subheadline.weight(.semibold))
                                Text(item.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(item.updatedAt, style: .time)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func color(for state: TaskState) -> Color {
        switch state {
        case .idle: return .secondary
        case .running: return .blue
        case .completed: return .green
        case .failed: return .red
        }
    }
}
