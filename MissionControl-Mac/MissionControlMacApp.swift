import SwiftUI

@main
struct MissionControlMacApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            AppShellView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .tint(MCColor.accent)
                .frame(minWidth: 1100, minHeight: 740)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            CommandGroup(after: .newItem) {
                Button("New Session") { store.addSession() }
                    .keyboardShortcut("n", modifiers: [.command, .shift])

                Button("Run Health Check") {
                    Task { await store.runHealthCheck() }
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
            }
        }

        Settings {
            SettingsView()
                .environmentObject(store)
                .frame(width: 620, height: 460)
        }
    }
}
