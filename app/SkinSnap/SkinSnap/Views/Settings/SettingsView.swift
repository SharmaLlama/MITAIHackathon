import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @State private var showingResetAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("App Settings")) {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                    Toggle("Dark Mode", isOn: $darkModeEnabled)
                        .onChange(of: darkModeEnabled) { _, newValue in
                            // Would need proper implementation to change app appearance
                            print("Dark mode changed to: \(newValue)")
                        }
                }
                
                Section(header: Text("Health Data")) {
                    Button("Connect to Health App") {
                        healthKitManager.requestAuthorization()
                        healthKitManager.requestExtendedAuthorization()
                    }
                    
                    Text("Connected: \(healthKitManager.isAuthorized ? "Yes" : "No")")
                        .foregroundColor(healthKitManager.isAuthorized ? .green : .gray)
                }
                
                Section(header: Text("Data Management")) {
                    Button("Reset All Data") {
                        showingResetAlert = true
                    }
                    .foregroundColor(.red)
                }
                
                Section(header: Text("About")) {
                    Text("SkinSnap Pro 1.3")
                    Text("© SharmaLlamaIncorporated")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
