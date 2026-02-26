import SwiftUI

struct QuickActionsCard: View {
    let onHealth: () -> Void
    let onNewSession: () -> Void
    let onGoChat: () -> Void

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: MCSpacing.sm) {
                Text("Quick Actions")
                    .font(.headline)

                HStack(spacing: MCSpacing.sm) {
                    Button("Health Check", action: onHealth)
                        .buttonStyle(.borderedProminent)
                    Button("New Session", action: onNewSession)
                        .buttonStyle(.bordered)
                    Button("Open Chat", action: onGoChat)
                        .buttonStyle(.bordered)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
