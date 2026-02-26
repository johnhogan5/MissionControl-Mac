import SwiftUI

struct IntelligenceView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        VStack(alignment: .leading, spacing: MCSpacing.md) {
            Text("Intelligence")
                .font(.largeTitle.weight(.semibold))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: MCSpacing.sm) {
                StatusCard(title: "Primary Model", value: store.profile.model, footnote: "Current default")
                StatusCard(title: "Fallback Stack", value: "Sonnet → Opus", footnote: "Escalation policy")
                StatusCard(title: "Last Model Used", value: store.lastModelUsed ?? "—", footnote: "Latest response")
                StatusCard(title: "Last Latency", value: store.lastResponseLatencyMs.map { "\($0) ms" } ?? "—", footnote: "Round trip")
            }

            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Policy")
                        .font(.headline)
                    Text("Default to Codex for routine tasks. Escalate to Opus for high-stakes operations. Sonnet serves as fallback or second-opinion lane.")
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
    }
}
