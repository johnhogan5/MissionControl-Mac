import SwiftUI

struct StatusCard: View {
    let title: String
    let value: String
    let footnote: String

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(footnote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
