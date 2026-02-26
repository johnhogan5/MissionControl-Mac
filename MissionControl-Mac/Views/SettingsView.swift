import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        Form {
            Section("Connection Profile") {
                TextField("Profile Name", text: $store.profile.name)
                TextField("Gateway URL", text: $store.profile.baseURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                SecureField("Gateway Token", text: $store.token)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("Default Session Key", text: $store.profile.defaultSessionKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Section("Model + Polling") {
                TextField("Default Model", text: $store.profile.model)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Stepper(value: $store.profile.healthPollingSeconds, in: 5...120, step: 5) {
                    Text("Health poll interval: \(store.profile.healthPollingSeconds)s")
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
                        .foregroundStyle(store.isConnected ? .green : .secondary)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
    }
}
