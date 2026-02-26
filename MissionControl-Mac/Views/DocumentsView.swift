import SwiftUI

struct DocumentsView: View {
    private let docs: [(String, String)] = [
        ("Model Routing", "docs/model-routing.md"),
        ("Control Board", "docs/CONTROL.md"),
        ("Weekly Security Audits", "docs/ops/security-audit-weekly.md"),
        ("Weekly Update Status", "docs/ops/update-status-weekly.md")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: MCSpacing.md) {
            Text("Documents")
                .font(.largeTitle.weight(.semibold))

            GlassCard {
                VStack(alignment: .leading, spacing: MCSpacing.sm) {
                    Text("Workspace Documents")
                        .font(.headline)
                    ForEach(docs, id: \.0) { item in
                        HStack {
                            Label(item.0, systemImage: "doc.text")
                            Spacer()
                            Text(item.1)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            GlassCard {
                Text("Tip: use this section for generated plans, architecture docs, and runbooks.")
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}
