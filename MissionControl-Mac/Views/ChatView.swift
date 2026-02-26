import SwiftUI

struct ChatView: View {
    @EnvironmentObject private var store: AppStore
    @State private var input: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            header

            GlassCard {
                if let session = store.selectedSession {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: MCSpacing.sm) {
                                ForEach(session.messages) { msg in
                                    MessageRow(message: msg)
                                        .id(msg.id)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, MCSpacing.xs)
                        }
                        .onChange(of: session.messages.count) { _, _ in
                            if let last = session.messages.last?.id {
                                withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                            }
                        }
                    }
                } else {
                    ContentUnavailableView("No session selected", systemImage: "square.stack")
                }
            }

            GlassCard {
                HStack(spacing: MCSpacing.sm) {
                    TextField("Send a message", text: $input, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...6)

                    Button("Send") {
                        let text = input
                        input = ""
                        Task { await store.sendMessage(text) }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.isSending)
                }
            }
        }
    }

    @ViewBuilder
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(activeTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                Text(store.lastModelUsed ?? store.profile.model)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if store.isSending {
                ProgressView(value: store.taskProgress.percent)
                    .frame(width: 140)
                    .controlSize(.small)
            }
        }

        if store.taskProgress.state == .running {
            Text(store.taskProgress.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var activeTitle: String {
        store.selectedSession?.title ?? "Chat"
    }
}

private struct MessageRow: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == "assistant" {
                bubble
                Spacer(minLength: 48)
            } else {
                Spacer(minLength: 48)
                bubble
            }
        }
    }

    private var bubble: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(message.role.capitalized)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(message.text)
                .textSelection(.enabled)
                .font(.body)
        }
        .padding(MCSpacing.sm)
        .background(message.role == "assistant" ? MCPalette.assistant : MCPalette.user)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
