import SwiftUI

struct ProjectsView: View {
    private let projects = [
        ("Mission Control macOS", "In progress", "Native SwiftUI control center"),
        ("Mission Control iOS", "Baseline", "iPhone companion app"),
        ("OpenClaw Ops", "Stable", "Security + update automations")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: MCSpacing.md) {
            Text("Projects")
                .font(.largeTitle.weight(.semibold))

            ForEach(projects, id: \.0) { p in
                GlassCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(p.0)
                                .font(.headline)
                            Text(p.2)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(p.1)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.thinMaterial)
                            .clipShape(Capsule())
                    }
                }
            }
            Spacer()
        }
    }
}
