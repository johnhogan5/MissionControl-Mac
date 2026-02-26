import SwiftUI

struct TaskProgressCard: View {
    let progress: TaskProgress

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: MCSpacing.sm) {
                HStack {
                    Text("Active Task")
                        .font(.headline)
                    Spacer()
                    statusBadge
                }

                Text(progress.taskTitle)
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(progress.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ProgressView(value: progress.percent)
                    .tint(progress.state == .failed ? .red : .accentColor)

                Text("\(Int(progress.percent * 100))% complete")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !progress.steps.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(progress.steps) { step in
                            HStack(spacing: 8) {
                                Image(systemName: step.isDone ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(step.isDone ? .green : .secondary)
                                Text(step.title)
                                    .font(.caption)
                                    .foregroundStyle(step.isDone ? .primary : .secondary)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var statusBadge: some View {
        Text(progress.state.rawValue.capitalized)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.thinMaterial)
            .clipShape(Capsule())
    }
}
