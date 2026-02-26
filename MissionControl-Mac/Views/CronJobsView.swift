import SwiftUI

struct CronJobsView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        VStack(alignment: .leading, spacing: MCSpacing.md) {
            Text("Cron Jobs")
                .font(.largeTitle.weight(.semibold))

            GlassCard {
                List(store.cronJobs) { job in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(job.name)
                                .font(.headline)
                            Text(job.schedule)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Last run: \(job.lastRun)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { job.enabled },
                            set: { _ in store.toggleCronJob(job.id) }
                        ))
                        .labelsHidden()
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 260)
            }

            GlassCard {
                Text("These toggles control local visibility state. Server-side cron remains managed by OpenClaw.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}
