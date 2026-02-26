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
                Button(store.isRefreshingGatewayData ? "Refreshing…" : "Refresh Gateway") {
                    Task { await store.refreshGatewayData() }
                }
                .buttonStyle(.bordered)
                .disabled(store.isRefreshingGatewayData)

                Button("New") { store.addSession() }
                    .buttonStyle(.borderedProminent)
            }

            HStack(alignment: .top, spacing: MCSpacing.md) {
                localSessionsCard
                gatewaySessionsCard
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
        .onAppear {
            if store.gatewaySessions.isEmpty {
                Task { await store.refreshGatewayData() }
            }
        }
    }

    private var localSessionsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Local Sessions")
                    .font(.headline)
                    .foregroundStyle(MCColor.textPrimary)

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
                .frame(minHeight: 320)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var gatewaySessionsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Gateway Sessions")
                    .font(.headline)
                    .foregroundStyle(MCColor.textPrimary)

                if store.gatewaySessions.isEmpty {
                    Text(store.gatewaySyncError ?? "No gateway sessions found yet")
                        .font(MCFont.body)
                        .foregroundStyle(MCColor.textSecondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                } else {
                    List(store.gatewaySessions) { session in
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(session.title)
                                    .font(.system(size: 14, weight: .semibold))
                                Text(session.id)
                                    .font(.caption)
                                    .foregroundStyle(MCColor.textSecondary)
                                    .textSelection(.enabled)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                if let count = session.messageCount {
                                    Text("\(count) msgs")
                                        .font(.caption2)
                                        .foregroundStyle(MCColor.textSecondary)
                                }
                                Text(session.updatedAt?.formatted(date: .omitted, time: .shortened) ?? "—")
                                    .font(.caption2)
                                    .foregroundStyle(MCColor.textTertiary)
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 320, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity)
    }
}
