import SwiftUI
import SwiftData

struct DailyLogView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var healthKitManager: HealthKitManager
    @State private var selectedDate = Date()
    @State private var isAdvancedMode = false
    
    // Existing fields
    @State private var sleepHours: Double = 7.0
    @State private var stressLevel: Int = 3
    @State private var waterIntake: Int = 6
    @State private var dairyConsumed = false
    @State private var sugarConsumed = false
    @State private var alcoholConsumed = false
    
    // New diet fields
    @State private var fastFoodConsumed = false
    @State private var highProteinMeal = false
    @State private var fruitsAndVeggiesServings: Int = 2
    
    // New stress/mood fields
    @State private var moodRating: Int = 3
    @State private var anxietyLevel: Int = 1
    
    // New location/travel fields
    @State private var traveledRecently = false
    @State private var currentLocation: String = ""
    @State private var climateChange = false
    
    // New product usage fields
    @State private var usedSunscreen = false
    @State private var usedMakeup = false
    @State private var usedFaceWash = false
    @State private var usedMoisturizer = false
    @State private var usedAcneTreatment = false
    @State private var changedPillowcase = false
    
    // New outdoor exposure
    @State private var outdoorHours: Double = 1.0
    @State private var sunExposureLevel: Int = 1
    
    @State private var notes = ""
    @State private var showingHealthKitDataAlert = false
    
    // For UI organization
    @State private var expandedSections = Set<String>(["Date", "Sleep"])
    
    // Date data tracking
    @State private var datesWithEntries: Set<DateComponents> = []
    @State private var isLoading = true
    
    // Save confirmation
    @State private var showingSaveConfirmation = false
    @State private var saveMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Date")) {
                    HStack {
                        DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                            .onChange(of: selectedDate) { _, _ in
                                loadExistingEntry()
                            }
                        
                        if hasEntryForSelectedDate() {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 10, height: 10)
                        }
                    }
                    
                    Toggle("Advanced Mode", isOn: $isAdvancedMode)
                        .onChange(of: isAdvancedMode) { oldValue, newValue in
                            // If switching to advanced, make sure all sections are visible
                            if newValue {
                                expandedSections = Set(["Date", "Sleep", "Stress & Mood", "Diet & Hydration", "Environment"])
                                if oldValue == false {
                                    // Only show this message when toggling from basic to advanced
                                    expandedSections.insert("Skincare Products")
                                }
                            } else {
                                // If switching to basic, collapse advanced sections
                                expandedSections.remove("Skincare Products")
                            }
                        }
                }
                
                // Sleep Section - Available in both modes
                DisclosureGroup(
                    isExpanded: Binding<Bool>(
                        get: { expandedSections.contains("Sleep") },
                        set: { isExpanded in
                            if isExpanded {
                                expandedSections.insert("Sleep")
                            } else {
                                expandedSections.remove("Sleep")
                            }
                        }
                    ),
                    content: {
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
                    },
                    label: {
                        HStack {
                            Image(systemName: "bed.double.fill")
                                .foregroundColor(.blue)
                            Text("Sleep")
                                .fontWeight(.semibold)
                        }
                    }
                )
                .onTapGesture {
                    if expandedSections.contains("Sleep") {
                        expandedSections.remove("Sleep")
                    } else {
                        expandedSections.insert("Sleep")
                    }
                }
                
                // Stress & Mood - Simplified in basic mode
                DisclosureGroup(
                    isExpanded: Binding<Bool>(
                        get: { expandedSections.contains("Stress & Mood") },
                        set: { isExpanded in
                            if isExpanded {
                                expandedSections.insert("Stress & Mood")
                            } else {
                                expandedSections.remove("Stress & Mood")
                            }
                        }
                    ),
                    content: {
                        VStack(spacing: 16) {
                            // Stress level - available in both modes
                            VStack(alignment: .leading) {
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
                            
                            // Advanced mode fields
                            if isAdvancedMode {
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text("Mood Rating: \(moodRating)")
                                        Spacer()
                                    }
                                    
                                    Picker("Mood Rating", selection: $moodRating) {
                                        Text("1 - Very Bad").tag(1)
                                        Text("2 - Bad").tag(2)
                                        Text("3 - Neutral").tag(3)
                                        Text("4 - Good").tag(4)
                                        Text("5 - Excellent").tag(5)
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                }
                                
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text("Anxiety Level: \(anxietyLevel)")
                                        Spacer()
                                    }
                                    
                                    Picker("Anxiety Level", selection: $anxietyLevel) {
                                        Text("1 - None").tag(1)
                                        Text("2 - Mild").tag(2)
                                        Text("3 - Moderate").tag(3)
                                        Text("4 - High").tag(4)
                                        Text("5 - Severe").tag(5)
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                }
                            }
                        }
                    },
                    label: {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(.purple)
                            Text("Stress & Mood")
                                .fontWeight(.semibold)
                        }
                    }
                )
                .onTapGesture {
                    if expandedSections.contains("Stress & Mood") {
                        expandedSections.remove("Stress & Mood")
                    } else {
                        expandedSections.insert("Stress & Mood")
                    }
                }
                
                // Diet & Hydration - Simplified in basic mode
                DisclosureGroup(
                    isExpanded: Binding<Bool>(
                        get: { expandedSections.contains("Diet & Hydration") },
                        set: { isExpanded in
                            if isExpanded {
                                expandedSections.insert("Diet & Hydration")
                            } else {
                                expandedSections.remove("Diet & Hydration")
                            }
                        }
                    ),
                    content: {
                        VStack(spacing: 16) {
                            // Basic mode fields
                            VStack {
                                HStack {
                                    Text("Glasses of Water: \(waterIntake)")
                                    Spacer()
                                }
                                
                                Stepper("", value: $waterIntake, in: 0...20)
                            }
                            
                            Toggle("Dairy Consumed", isOn: $dairyConsumed)
                            Toggle("High Sugar Consumed", isOn: $sugarConsumed)
                            Toggle("Alcohol Consumed", isOn: $alcoholConsumed)
                            
                            // Advanced mode fields
                            if isAdvancedMode {
                                Toggle("Fast Food Consumed", isOn: $fastFoodConsumed)
                                Toggle("High Protein Meal", isOn: $highProteinMeal)
                                
                                VStack {
                                    HStack {
                                        Text("Fruits & Vegetables (servings): \(fruitsAndVeggiesServings)")
                                        Spacer()
                                    }
                                    
                                    Stepper("", value: $fruitsAndVeggiesServings, in: 0...10)
                                }
                            }
                        }
                    },
                    label: {
                        HStack {
                            Image(systemName: "fork.knife")
                                .foregroundColor(.green)
                            Text("Diet & Hydration")
                                .fontWeight(.semibold)
                        }
                    }
                )
                .onTapGesture {
                    if expandedSections.contains("Diet & Hydration") {
                        expandedSections.remove("Diet & Hydration")
                    } else {
                        expandedSections.insert("Diet & Hydration")
                    }
                }
                
                // Skincare Products - Advanced mode only
                if isAdvancedMode {
                    DisclosureGroup(
                        isExpanded: Binding<Bool>(
                            get: { expandedSections.contains("Skincare Products") },
                            set: { isExpanded in
                                if isExpanded {
                                    expandedSections.insert("Skincare Products")
                                } else {
                                    expandedSections.remove("Skincare Products")
                                }
                            }
                        ),
                        content: {
                            VStack {
                                Toggle("Used Sunscreen", isOn: $usedSunscreen)
                                Toggle("Used Makeup", isOn: $usedMakeup)
                                Toggle("Used Face Wash", isOn: $usedFaceWash)
                                Toggle("Used Moisturizer", isOn: $usedMoisturizer)
                                Toggle("Used Acne Treatment", isOn: $usedAcneTreatment)
                                Toggle("Changed Pillowcase", isOn: $changedPillowcase)
                            }
                        },
                        label: {
                            HStack {
                                Image(systemName: "drop.fill")
                                    .foregroundColor(.blue)
                                Text("Skincare Products")
                                    .fontWeight(.semibold)
                            }
                        }
                    )
                    .onTapGesture {
                        if expandedSections.contains("Skincare Products") {
                            expandedSections.remove("Skincare Products")
                        } else {
                            expandedSections.insert("Skincare Products")
                        }
                    }
                }
                
                // Environment - Simplified in basic mode
                DisclosureGroup(
                    isExpanded: Binding<Bool>(
                        get: { expandedSections.contains("Environment") },
                        set: { isExpanded in
                            if isExpanded {
                                expandedSections.insert("Environment")
                            } else {
                                expandedSections.remove("Environment")
                            }
                        }
                    ),
                    content: {
                        VStack(spacing: 16) {
                            // Basic mode field
                            VStack {
                                HStack {
                                    Text("Outdoor Hours: \(outdoorHours, specifier: "%.1f")")
                                    Spacer()
                                }
                                
                                Slider(value: $outdoorHours, in: 0...12, step: 0.5)
                            }
                            
                            // Advanced mode fields
                            if isAdvancedMode {
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text("Sun Exposure: \(sunExposureLevel)")
                                        Spacer()
                                    }
                                    
                                    Picker("Sun Exposure", selection: $sunExposureLevel) {
                                        Text("1 - None").tag(1)
                                        Text("2 - Limited").tag(2)
                                        Text("3 - Moderate").tag(3)
                                        Text("4 - Significant").tag(4)
                                        Text("5 - Intense").tag(5)
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                }
                                
                                Toggle("Traveled Recently", isOn: $traveledRecently)
                                
                                if traveledRecently {
                                    TextField("Current Location", text: $currentLocation)
                                    Toggle("Climate Change", isOn: $climateChange)
                                }
                            }
                        }
                    },
                    label: {
                        HStack {
                            Image(systemName: "sun.max.fill")
                                .foregroundColor(.orange)
                            Text("Environment")
                                .fontWeight(.semibold)
                        }
                    }
                )
                .onTapGesture {
                    if expandedSections.contains("Environment") {
                        expandedSections.remove("Environment")
                    } else {
                        expandedSections.insert("Environment")
                    }
                }
                
                // Notes - Available in both modes
                if isAdvancedMode {
                    DisclosureGroup(
                        isExpanded: Binding<Bool>(
                            get: { expandedSections.contains("Notes") },
                            set: { isExpanded in
                                if isExpanded {
                                    expandedSections.insert("Notes")
                                } else {
                                    expandedSections.remove("Notes")
                                }
                            }
                        ),
                        content: {
                            TextEditor(text: $notes)
                                .frame(height: 100)
                        },
                        label: {
                            HStack {
                                Image(systemName: "note.text")
                                    .foregroundColor(.gray)
                                Text("Notes")
                                    .fontWeight(.semibold)
                            }
                        }
                    )
                    .onTapGesture {
                        if expandedSections.contains("Notes") {
                            expandedSections.remove("Notes")
                        } else {
                            expandedSections.insert("Notes")
                        }
                    }
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
                loadDatesWithEntries()
                loadExistingEntry()
            }
            .alert(isPresented: $showingHealthKitDataAlert) {
                Alert(
                    title: Text("HealthKit Data"),
                    message: Text("Sleep data has been imported from HealthKit."),
                    dismissButton: .default(Text("OK"))
                )
            }
            .overlay(
                Group {
                    if isLoading {
                        ProgressView("Loading data...")
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)
                    }
                }
            )
            // Success confirmation
            .overlay(
                ZStack {
                    if showingSaveConfirmation {
                        VStack {
                            Spacer()
                            
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title)
                                
                                Text(saveMessage)
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(10)
                            .padding(.bottom, 40)
                        }
                        .transition(.move(edge: .bottom))
                        .animation(.easeInOut(duration: 0.3), value: showingSaveConfirmation)
                        .onAppear {
                            // Auto-dismiss after 2 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    showingSaveConfirmation = false
                                }
                            }
                        }
                    }
                }
            )
        }
    }
    
    // Function to check if the selected date has an entry
    private func hasEntryForSelectedDate() -> Bool {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        return datesWithEntries.contains(components)
    }
    
    // Load all dates that have entries
    private func loadDatesWithEntries() {
        isLoading = true
        
        let descriptor = FetchDescriptor<LifestyleEntry>()
        
        do {
            let entries = try modelContext.fetch(descriptor)
            let calendar = Calendar.current
            
            datesWithEntries = Set(entries.map { entry in
                calendar.dateComponents([.year, .month, .day], from: entry.date)
            })
            
            isLoading = false
        } catch {
            print("Error fetching lifestyle entries: \(error.localizedDescription)")
            isLoading = false
        }
    }
    
    private func loadExistingEntry() {
        // Using Swift Data to fetch entry for selected date
        if let existingEntry = LifestyleEntry.entryForDate(modelContext: modelContext, date: selectedDate) {
            // Load existing fields
            sleepHours = existingEntry.sleepHours
            stressLevel = existingEntry.stressLevel
            waterIntake = existingEntry.waterIntake
            dairyConsumed = existingEntry.dairyConsumed
            sugarConsumed = existingEntry.sugarConsumed
            alcoholConsumed = existingEntry.alcoholConsumed
            
            // Load new fields
            fastFoodConsumed = existingEntry.fastFoodConsumed
            highProteinMeal = existingEntry.highProteinMeal
            fruitsAndVeggiesServings = existingEntry.fruitsAndVeggiesServings
            moodRating = existingEntry.moodRating
            anxietyLevel = existingEntry.anxietyLevel
            traveledRecently = existingEntry.traveledRecently
            currentLocation = existingEntry.currentLocation ?? ""
            climateChange = existingEntry.climateChange
            usedSunscreen = existingEntry.usedSunscreen
            usedMakeup = existingEntry.usedMakeup
            usedFaceWash = existingEntry.usedFaceWash
            usedMoisturizer = existingEntry.usedMoisturizer
            usedAcneTreatment = existingEntry.usedAcneTreatment
            changedPillowcase = existingEntry.changedPillowcase
            outdoorHours = existingEntry.outdoorHours
            sunExposureLevel = existingEntry.sunExposureLevel
            notes = existingEntry.notes ?? ""
        } else {
            // Reset to defaults
            sleepHours = 7.0
            stressLevel = 3
            waterIntake = 6
            dairyConsumed = false
            sugarConsumed = false
            alcoholConsumed = false
            
            // Reset new fields
            fastFoodConsumed = false
            highProteinMeal = false
            fruitsAndVeggiesServings = 2
            moodRating = 3
            anxietyLevel = 1
            traveledRecently = false
            currentLocation = ""
            climateChange = false
            usedSunscreen = false
            usedMakeup = false
            usedFaceWash = false
            usedMoisturizer = false
            usedAcneTreatment = false
            changedPillowcase = false
            outdoorHours = 1.0
            sunExposureLevel = 1
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
        let isNewEntry = LifestyleEntry.entryForDate(modelContext: modelContext, date: selectedDate) == nil
        
        // Check if entry already exists using SwiftData
        if let existingEntry = LifestyleEntry.entryForDate(modelContext: modelContext, date: selectedDate) {
            // Update existing entry
            existingEntry.sleepHours = sleepHours
            existingEntry.stressLevel = stressLevel
            existingEntry.waterIntake = waterIntake
            existingEntry.dairyConsumed = dairyConsumed
            existingEntry.sugarConsumed = sugarConsumed
            existingEntry.alcoholConsumed = alcoholConsumed
            
            // Update new fields
            existingEntry.fastFoodConsumed = fastFoodConsumed
            existingEntry.highProteinMeal = highProteinMeal
            existingEntry.fruitsAndVeggiesServings = fruitsAndVeggiesServings
            existingEntry.moodRating = moodRating
            existingEntry.anxietyLevel = anxietyLevel
            existingEntry.traveledRecently = traveledRecently
            existingEntry.currentLocation = currentLocation.isEmpty ? nil : currentLocation
            existingEntry.climateChange = climateChange
            existingEntry.usedSunscreen = usedSunscreen
            existingEntry.usedMakeup = usedMakeup
            existingEntry.usedFaceWash = usedFaceWash
            existingEntry.usedMoisturizer = usedMoisturizer
            existingEntry.usedAcneTreatment = usedAcneTreatment
            existingEntry.changedPillowcase = changedPillowcase
            existingEntry.outdoorHours = outdoorHours
            existingEntry.sunExposureLevel = sunExposureLevel
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
                fastFoodConsumed: fastFoodConsumed,
                highProteinMeal: highProteinMeal,
                fruitsAndVeggiesServings: fruitsAndVeggiesServings,
                moodRating: moodRating,
                anxietyLevel: anxietyLevel,
                traveledRecently: traveledRecently,
                currentLocation: currentLocation.isEmpty ? nil : currentLocation,
                climateChange: climateChange,
                usedSunscreen: usedSunscreen,
                usedMakeup : usedMakeup,
                usedFaceWash : usedFaceWash,
                usedMoisturizer : usedMoisturizer,
                usedAcneTreatment : usedAcneTreatment,
                changedPillowcase : changedPillowcase,
                outdoorHours : outdoorHours,
                sunExposureLevel : sunExposureLevel,
                notes : notes
            )
            
            // Add to SwiftData
            modelContext.insert(newEntry)
        }
        
        // Save the changes
        do {
            try modelContext.save()
            
            // Show success message
            if isNewEntry {
                saveMessage = "Entry created successfully!"
            } else {
                saveMessage = "Entry updated successfully!"
            }
            withAnimation {
                showingSaveConfirmation = true
            }
            
            // Update the list of dates with entries
            loadDatesWithEntries()
        } catch {
            print("Error saving lifestyle entry: \(error.localizedDescription)")
            saveMessage = "Error saving: \(error.localizedDescription)"
            withAnimation {
                showingSaveConfirmation = true
            }
        }
    }
}
