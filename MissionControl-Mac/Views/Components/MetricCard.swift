import SwiftUI

struct MetricCard: View {
    let title: String
    let value: String
    let hint: String
    let tint: Color

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title.uppercased())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Circle().fill(tint).frame(width: 8, height: 8)
                }
                Text(value)
                    .font(.title3.weight(.semibold))
                Text(hint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
