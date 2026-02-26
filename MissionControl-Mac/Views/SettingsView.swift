import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        Form {
            Section("Connection Profile") {
                TextField("Profile Name", text: $store.profile.name)
                TextField("Gateway URL", text: $store.profile.baseURL)
                SecureField("Gateway Token", text: $store.token)
                TextField("Default Session Key", text: $store.profile.defaultSessionKey)
            }

            Section("Model + Polling") {
                TextField("Default Model", text: $store.profile.model)

                Stepper(value: $store.profile.healthPollingSeconds, in: 5...120, step: 5) {
                    Text("Health poll interval: \(store.profile.healthPollingSeconds)s")
                }
            }

            if !store.settingsValidationErrors.isEmpty {
                Section("Validation") {
                    ForEach(store.settingsValidationErrors, id: \.self) { issue in
                        Label(issue, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(MCColor.red)
                    }
                }
            }

            Section {
                HStack {
                    Button("Save") { store.saveProfile() }
                        .buttonStyle(.borderedProminent)

                    Button("Test Connection") {
                        Task { await store.runHealthCheck() }
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Text(store.connectionLabel)
                        .foregroundStyle(store.isConnected ? MCColor.green : MCColor.textSecondary)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
    }
}
