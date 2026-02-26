import SwiftUI

struct AppShellView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        HStack(spacing: 0) {
            SidebarView()
                .frame(width: 220)

            Divider().overlay(MCColor.divider)

            ZStack {
                MCColor.bg.ignoresSafeArea()

                ScrollView {
                    Group {
                        switch store.selectedSection {
                        case .dashboard: DashboardView()
                        case .journal: JournalView()
                        case .documents: DocumentsView()
                        case .agents: ChatView()
                        case .intelligence: IntelligenceView()
                        case .weeklyRecaps: WeeklyRecapsView()
                        case .clients: SessionsView()
                        case .logs: LogsView()
                        case .cronJobs: CronJobsView()
                        case .apiUsage: APIUsageView()
                        case .workshop: WorkshopView()
                        case .projects: ProjectsView()
                        case .settings: SettingsView()
                        }
                    }
                    .padding(32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                HStack(spacing: 8) {
                    Text("Mission Control")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(MCColor.textPrimary)
                    StatusDot(color: store.isConnected ? MCColor.green : MCColor.red)
                    Text(store.isConnected ? "Connected" : "Disconnected")
                        .font(.system(size: 12))
                        .foregroundStyle(MCColor.textSecondary)
                }
            }
        }
    }
}
