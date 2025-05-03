import SwiftUI
import SwiftData
import Vision

@main
struct SkinSnapApp: App {
    @StateObject private var healthKitManager = HealthKitManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(healthKitManager)
                .onAppear {
                    // Request standard and extended HealthKit permissions
                    healthKitManager.requestAuthorization()
                    healthKitManager.requestExtendedAuthorization()
                }
        }
        // Configure the SwiftData model container with schema migration options
        .modelContainer(for: [SkinEntry.self, RegionSeverity.self, LifestyleEntry.self])
            
    }
}

// ContentView serves as the main tab controller
struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ScanView()
                .tabItem {
                    Label("Scan", systemImage: "camera.fill")
                }
                .tag(0)
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(1)
            
            DailyLogView()
                .tabItem {
                    Label("Daily Log", systemImage: "list.bullet.clipboard")
                }
                .tag(2)
            
//            FitnessView()
//                .tabItem {
//                    Label("Fitness", systemImage: "figure.walk")
//                }
//                .tag(3)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("App Settings")) {
                    Toggle("Enable Notifications", isOn: .constant(true))
                    Toggle("Dark Mode", isOn: .constant(false))
                }
                
                Section(header: Text("Health Data")) {
                    Button("Connect to Health App") {
                        healthKitManager.requestAuthorization()
                        healthKitManager.requestExtendedAuthorization()
                    }
                    
                    Text("Connected: \(healthKitManager.isAuthorized ? "Yes" : "No")")
                        .foregroundColor(healthKitManager.isAuthorized ? .green : .gray)
                }
                
                Section(header: Text("About")) {
                    Text("SnapSkin Pro 1.2")
                    Text("© SharmaLlamaIncorporated")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
