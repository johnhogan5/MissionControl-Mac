import SwiftUI

struct LogsView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Event Logs")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("Clear") {
                    store.events = []
                    Persistence.saveEvents([])
                }
            }

            GlassCard {
                List(store.events) { event in
                    HStack(alignment: .top, spacing: 10) {
                        Text(event.ts, style: .time)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 72, alignment: .leading)

                        Text(event.level.rawValue.uppercased())
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.thinMaterial)
                            .clipShape(Capsule())

                        Text(event.message)
                            .font(.body)
                    }
                    .padding(.vertical, 2)
                }
                .scrollContentBackground(.hidden)
                .listStyle(.plain)
                .frame(minHeight: 360)
            }
        }
    }
}
