import SwiftUI
import SwiftData

struct DailyLogView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var healthKitManager: HealthKitManager
    @State private var selectedDate = Date()
    @State private var sleepHours: Double = 7.0
    @State private var stressLevel: Int = 3
    @State private var waterIntake: Int = 6
    @State private var dairyConsumed = false
    @State private var sugarConsumed = false
    @State private var alcoholConsumed = false
    @State private var notes = ""
    @State private var showingHealthKitDataAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Date")) {
                    DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                        .onChange(of: selectedDate) { _, _ in
                            loadExistingEntry()
                        }
                }
                
                Section(header: Text("Sleep")) {
                    VStack {
                        HStack {
                            Text("Sleep Duration: \(sleepHours, specifier: "%.1f") hours")
                            Spacer()
                            Button(action: {
                                healthKitManager.fetchSleepData(for: selectedDate) { sleepHours in
                                    if let sleepHours = sleepHours {
                                        self.sleepHours = sleepHours
                                        showingHealthKitDataAlert = true
                                    }
                                }
                            }) {
                                Image(systemName: "waveform.path.ecg")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Slider(value: $sleepHours, in: 0...12, step: 0.5)
                    }
                }
                
                Section(header: Text("Stress Level")) {
                    VStack {
                        HStack {
                            Text("Stress Level: \(stressLevel)")
                            Spacer()
                        }
                        
                        Picker("Stress Level", selection: $stressLevel) {
                            Text("1 - Very Low").tag(1)
                            Text("2 - Low").tag(2)
                            Text("3 - Average").tag(3)
                            Text("4 - High").tag(4)
                            Text("5 - Very High").tag(5)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                
                Section(header: Text("Water Intake")) {
                    VStack {
                        HStack {
                            Text("Glasses of Water: \(waterIntake)")
                            Spacer()
                        }
                        
                        Stepper("", value: $waterIntake, in: 0...20)
                    }
                }
                
                Section(header: Text("Dietary Factors")) {
                    Toggle("Dairy Consumed", isOn: $dairyConsumed)
                    Toggle("High Sugar Consumed", isOn: $sugarConsumed)
                    Toggle("Alcohol Consumed", isOn: $alcoholConsumed)
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
                
                Button(action: saveEntry) {
                    Text("Save")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            .navigationTitle("Daily Log")
            .onAppear {
                loadExistingEntry()
            }
            .alert(isPresented: $showingHealthKitDataAlert) {
                Alert(
                    title: Text("HealthKit Data"),
                    message: Text("Sleep data has been imported from HealthKit."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func loadExistingEntry() {
        // Using Swift Data to fetch entry for selected date
        if let existingEntry = LifestyleEntry.entryForDate(modelContext: modelContext, date: selectedDate) {
            sleepHours = existingEntry.sleepHours
            stressLevel = existingEntry.stressLevel
            waterIntake = existingEntry.waterIntake
            dairyConsumed = existingEntry.dairyConsumed
            sugarConsumed = existingEntry.sugarConsumed
            alcoholConsumed = existingEntry.alcoholConsumed
            notes = existingEntry.notes ?? ""
        } else {
            // Reset to defaults
            sleepHours = 7.0
            stressLevel = 3
            waterIntake = 6
            dairyConsumed = false
            sugarConsumed = false
            alcoholConsumed = false
            notes = ""
            
            // Try to fetch from HealthKit
            healthKitManager.fetchSleepData(for: selectedDate) { sleepHours in
                if let sleepHours = sleepHours {
                    self.sleepHours = sleepHours
                }
            }
        }
    }
    
    private func saveEntry() {
        // Check if entry already exists using SwiftData
        if let existingEntry = LifestyleEntry.entryForDate(modelContext: modelContext, date: selectedDate) {
            // Update existing entry
            existingEntry.sleepHours = sleepHours
            existingEntry.stressLevel = stressLevel
            existingEntry.waterIntake = waterIntake
            existingEntry.dairyConsumed = dairyConsumed
            existingEntry.sugarConsumed = sugarConsumed
            existingEntry.alcoholConsumed = alcoholConsumed
            existingEntry.notes = notes
        } else {
            // Create new entry using Swift Data
            let newEntry = LifestyleEntry(
                date: selectedDate,
                sleepHours: sleepHours,
                stressLevel: stressLevel,
                waterIntake: waterIntake,
                dairyConsumed: dairyConsumed,
                sugarConsumed: sugarConsumed,
                alcoholConsumed: alcoholConsumed,
                notes: notes
            )
            
            // Add to SwiftData
            modelContext.insert(newEntry)
        }
        
        // Save the changes
        do {
            try modelContext.save()
        } catch {
            print("Error saving lifestyle entry: \(error.localizedDescription)")
        }
    }
}
