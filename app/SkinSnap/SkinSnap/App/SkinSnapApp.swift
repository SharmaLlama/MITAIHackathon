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
