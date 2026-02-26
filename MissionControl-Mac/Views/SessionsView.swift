import SwiftUI

struct SessionsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var renameText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Sessions")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("New") { store.addSession() }
                    .buttonStyle(.borderedProminent)
            }

            GlassCard {
                List(selection: $store.selectedSessionID) {
                    ForEach(store.sessions) { session in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.title)
                                    .font(.headline)
                                Text(session.sessionKey)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(session.updatedAt, style: .relative)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .tag(session.id)
                        .contextMenu {
                            Button("Use in Chat") {
                                store.selectedSessionID = session.id
                                store.selectedSection = .agents
                            }
                            Button("Delete", role: .destructive) {
                                store.deleteSession(session.id)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.plain)
                .frame(minHeight: 300)
            }

            if let selected = store.selectedSession {
                Divider()
                Text("Edit Selected")
                    .font(.headline)

                HStack {
                    TextField("Session title", text: Binding(
                        get: { renameText.isEmpty ? selected.title : renameText },
                        set: { renameText = $0 }
                    ))
                    Button("Rename") {
                        let newTitle = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !newTitle.isEmpty else { return }
                        store.renameSession(selected.id, title: newTitle)
                        renameText = ""
                    }
                }
            }
        }
    }
}
