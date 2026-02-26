import SwiftUI

struct WeeklyRecapsView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        VStack(alignment: .leading, spacing: MCSpacing.md) {
            Text("Weekly Recaps")
                .font(.largeTitle.weight(.semibold))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: MCSpacing.sm) {
                MetricCard(title: "Completed", value: "\(store.taskHistory.filter { $0.state == .completed }.count)", hint: "Recent tasks", tint: .green)
                MetricCard(title: "Failed", value: "\(store.taskHistory.filter { $0.state == .failed }.count)", hint: "Needs review", tint: .red)
                MetricCard(title: "Events", value: "\(store.events.count)", hint: "Operational logs", tint: .blue)
            }

            TaskTimelineCard(items: store.taskHistory)
            Spacer()
        }
    }
}
