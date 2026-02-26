import SwiftUI

struct JournalView: View {
    @EnvironmentObject private var store: AppStore
    @State private var title = ""
    @State private var entryBody = ""

    var body: some View {
        VStack(alignment: .leading, spacing: MCSpacing.md) {
            Text("Journal")
                .font(.largeTitle.weight(.semibold))

            GlassCard {
                VStack(alignment: .leading, spacing: MCSpacing.sm) {
                    TextField("Entry title", text: $title)
                    TextEditor(text: $entryBody)
                        .frame(minHeight: 120)
                    HStack {
                        Spacer()
                        Button("Add Entry") {
                            store.addJournalEntry(title: title, body: entryBody)
                            title = ""
                            entryBody = ""
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }

            GlassCard {
                if store.journalEntries.isEmpty {
                    Text("No journal entries yet")
                        .foregroundStyle(.secondary)
                } else {
                    List(store.journalEntries) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.title)
                                .font(.headline)
                            Text(entry.body)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                            Text(entry.updatedAt, style: .date)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .contextMenu {
                            Button("Delete", role: .destructive) {
                                store.deleteJournalEntry(entry.id)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 240)
                }
            }
        }
    }
}
