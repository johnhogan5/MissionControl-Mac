import SwiftUI

struct LogsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var query: String = ""
    @State private var selectedLevel: LevelFilter = .all

    private var filteredEvents: [AppEvent] {
        store.events.filter { event in
            let levelMatch: Bool
            switch selectedLevel {
            case .all: levelMatch = true
            case .info: levelMatch = event.level == .info
            case .warning: levelMatch = event.level == .warning
            case .error: levelMatch = event.level == .error
            }

            let textMatch = query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || event.message.localizedCaseInsensitiveContains(query)

            return levelMatch && textMatch
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MCSpacing.md) {
            HStack {
                Text("Event Logs")
                    .font(MCFont.pageTitle)
                    .foregroundStyle(MCColor.textPrimary)
                Spacer()
                Button("Clear") {
                    store.clearEvents()
                }
                .buttonStyle(.bordered)
            }

            HStack(spacing: 10) {
                TextField("Search logs", text: $query)
                    .textFieldStyle(.roundedBorder)

                Picker("Level", selection: $selectedLevel) {
                    ForEach(LevelFilter.allCases) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 290)
            }

            MCCard {
                VStack(spacing: 0) {
                    logHeader

                    Divider().overlay(MCColor.divider)

                    ScrollView {
                        LazyVStack(spacing: 0) {
                            if filteredEvents.isEmpty {
                                Text("No logs match your filters")
                                    .font(MCFont.body)
                                    .foregroundStyle(MCColor.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 18)
                            } else {
                                ForEach(filteredEvents) { event in
                                    logRow(event)
                                    Divider().overlay(MCColor.divider.opacity(0.5))
                                }
                            }
                        }
                    }
                    .frame(minHeight: 360)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var logHeader: some View {
        HStack(spacing: 12) {
            Text("TIME")
                .frame(width: 160, alignment: .leading)
            Text("LEVEL")
                .frame(width: 90, alignment: .leading)
            Text("MESSAGE")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(MCFont.tiny)
        .foregroundStyle(MCColor.textTertiary)
        .padding(.vertical, 8)
    }

    private func logRow(_ event: AppEvent) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(event.ts.formatted(date: .abbreviated, time: .standard))
                .font(MCFont.caption)
                .foregroundStyle(MCColor.textSecondary)
                .frame(width: 160, alignment: .leading)

            Text(event.level.rawValue.uppercased())
                .font(MCFont.tiny)
                .foregroundStyle(color(for: event.level))
                .frame(width: 90, alignment: .leading)

            Text(event.message)
                .font(MCFont.body)
                .foregroundStyle(MCColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
        .padding(.vertical, 8)
    }

    private func color(for level: EventLevel) -> Color {
        switch level {
        case .info: return MCColor.accent
        case .warning: return MCColor.orange
        case .error: return MCColor.red
        }
    }
}

private enum LevelFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case info = "Info"
    case warning = "Warning"
    case error = "Error"

    var id: String { rawValue }
}
