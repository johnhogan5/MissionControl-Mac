import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var store: AppStore

    private let primarySections: [SidebarSection] = [.dashboard, .agents, .clients, .cronJobs, .logs, .settings]

    var body: some View {
        ZStack {
            MCColor.sidebarBg.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 34, height: 34)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Falken")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(MCColor.textPrimary)
                        Text(store.profile.name)
                            .font(.system(size: 11))
                            .foregroundStyle(MCColor.textSecondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(MCColor.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: MCCorner.md, style: .continuous))
                .padding(.horizontal, 12)
                .padding(.top, 10)

                chatQuickEntry
                    .padding(.horizontal, 12)
                    .padding(.top, 10)

                Text("NAVIGATION")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(MCColor.textTertiary)
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 6)

                VStack(spacing: 4) {
                    ForEach(primarySections.filter { $0 != .settings }) { section in
                        navRow(section)
                    }
                }
                .padding(.horizontal, 8)

                Spacer(minLength: 8)

                Divider().overlay(MCColor.divider)
                    .padding(.horizontal, 12)

                navRow(.settings)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 12)
            }
        }
        .frame(minWidth: 210, idealWidth: 224, maxWidth: 240)
    }

    private var chatQuickEntry: some View {
        let selected = store.selectedSection == .agents
        return Button {
            store.selectedSection = .agents
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "message.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(selected ? MCColor.textPrimary : MCColor.textSecondary)
                Text("Chat")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(selected ? MCColor.textPrimary : MCColor.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(selected ? MCColor.sidebarSelected : MCColor.cardBg)
            .overlay(RoundedRectangle(cornerRadius: MCCorner.md).stroke(MCColor.cardBorder, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: MCCorner.md, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func navRow(_ section: SidebarSection) -> some View {
        let selected = store.selectedSection == section
        return Button {
            store.selectedSection = section
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon(for: section))
                    .font(.system(size: 14))
                    .foregroundStyle(selected ? MCColor.textPrimary : MCColor.textSecondary)
                    .frame(width: 20)
                Text(label(for: section))
                    .font(.system(size: 13, weight: selected ? .semibold : .medium))
                    .foregroundStyle(selected ? MCColor.textPrimary : MCColor.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(selected ? MCColor.sidebarSelected : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func icon(for section: SidebarSection) -> String {
        switch section {
        case .dashboard: return "square.grid.2x2"
        case .journal: return "book"
        case .documents: return "doc.text"
        case .agents: return "message"
        case .intelligence: return "sparkles"
        case .weeklyRecaps: return "calendar"
        case .clients: return "person.2"
        case .cronJobs: return "clock"
        case .apiUsage: return "waveform.path.ecg"
        case .workshop: return "wrench.and.screwdriver"
        case .projects: return "folder"
        case .settings: return "gearshape"
        case .logs: return "list.bullet.rectangle"
        }
    }

    private func label(for section: SidebarSection) -> String {
        switch section {
        case .agents: return "Chat"
        case .clients: return "Sessions"
        case .logs: return "Logs"
        case .weeklyRecaps: return "Weekly Recap"
        default: return section.rawValue
        }
    }
}
