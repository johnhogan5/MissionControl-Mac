import SwiftUI

struct NavProfileCard: View {
    let title: String
    let subtitle: String
    let connected: Bool

    var body: some View {
        GlassCard {
            HStack(spacing: 10) {
                Circle()
                    .fill(connected ? Color.green.opacity(0.9) : Color.orange.opacity(0.9))
                    .frame(width: 10, height: 10)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
    }
}
