import SwiftUI
import SwiftData
import Charts

// Define TimeRange enum directly in this file to avoid scope issues
enum HistoryTimeRange {
    case week, month, threeMonths, sixMonths, year
}

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var healthKitManager: HealthKitManager
    
    // Using manual state instead of @Query to avoid ambiguity issues
    @State private var skinEntries: [SkinEntry] = []
    @State private var lifestyleEntries: [LifestyleEntry] = []
    
    @State private var selectedTimeRange: HistoryTimeRange = .week // Use local enum
    @State private var healthData: [Date: HealthDayData] = [:]
    @State private var correlationResults: [HistoryCorrelationResult] = [] // Renamed to avoid conflict
    @State private var isLoading = true
    
    var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let endDate = Date()
        
        switch selectedTimeRange {
        case .week:
            let startDate = calendar.date(byAdding: .day, value: -7, to: endDate)!
            return (startDate, endDate)
        case .month:
            let startDate = calendar.date(byAdding: .month, value: -1, to: endDate)!
            return (startDate, endDate)
        case .threeMonths:
            let startDate = calendar.date(byAdding: .month, value: -3, to: endDate)!
            return (startDate, endDate)
        case .sixMonths:
            let startDate = calendar.date(byAdding: .month, value: -6, to: endDate)!
            return (startDate, endDate)
        case .year:
            let startDate = calendar.date(byAdding: .year, value: -1, to: endDate)!
            return (startDate, endDate)
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Time range picker
                    Picker("Time Range", selection: $selectedTimeRange) {
                        Text("Week").tag(HistoryTimeRange.week)
                        Text("Month").tag(HistoryTimeRange.month)
                        Text("3 Months").tag(HistoryTimeRange.threeMonths)
                        Text("6 Months").tag(HistoryTimeRange.sixMonths)
                        Text("Year").tag(HistoryTimeRange.year)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .onChange(of: selectedTimeRange) { _, _ in
                        loadData()
                    }
                    
                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView("Loading data...")
                            Spacer()
                        }
                        .padding()
                    } else if skinEntries.isEmpty {
                        HStack {
                            Spacer()
                            VStack(spacing: 12) {
                                Image(systemName: "chart.xyaxis.line")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                Text("No skin data for this period")
                                    .font(.headline)
                                Text("Add scans to see your trends")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding()
                    } else {
                        // Debug info
                        Text("Displaying \(skinEntries.count) skin entries from \(formattedDate(dateRange.start)) to \(formattedDate(dateRange.end))")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        
                        // Severity Chart
                        HistoryChartSection(title: "Skin Severity Trend") {
                            HistorySeverityChart(skinEntries: skinEntries)
                        }
                        
                        // Affected Areas Chart - now a time series
                        HistoryChartSection(title: "Affected Areas Over Time") {
                            HistoryAffectedAreasTimeSeriesChart(skinEntries: skinEntries)
                        }
                        
                        // Correlation Analysis
                        HistoryCorrelationSection(title: "Potential Triggers") {
                            HistoryCorrelationView(correlations: correlationResults)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Analysis & Insights")
            .onAppear {
                loadData()
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func loadData() {
        isLoading = true
        
        let (startDate, endDate) = dateRange
        
        // Directly fetch entries using the helper methods instead of relying on @Query
        skinEntries = fetchSkinEntries(from: startDate, to: endDate)
        lifestyleEntries = fetchLifestyleEntries(from: startDate, to: endDate)
        
        // Sort entries by date for proper display
        skinEntries.sort { $0.date < $1.date }
        
        // Load health data
        healthKitManager.fetchHealthDataForCorrelation(startDate: startDate, endDate: endDate) { healthData in
            self.healthData = healthData
            
            // Perform correlation analysis
            self.correlationResults = self.performCorrelationAnalysis(
                skinEntries: self.skinEntries,
                lifestyleEntries: self.lifestyleEntries,
                healthData: self.healthData
            )
            
            self.isLoading = false
        }
    }
    
    // Helper method to fetch skin entries
    private func fetchSkinEntries(from startDate: Date, to endDate: Date) -> [SkinEntry] {
        let predicate = #Predicate<SkinEntry> { entry in
            entry.date >= startDate && entry.date <= endDate
        }
        
        let descriptor = FetchDescriptor<SkinEntry>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        
        do {
            let results = try modelContext.fetch(descriptor)
            print("Found \(results.count) skin entries between \(startDate) and \(endDate)")
            return results
        } catch {
            print("Error fetching skin entries: \(error.localizedDescription)")
            return []
        }
    }
    
    // Helper method to fetch lifestyle entries
    private func fetchLifestyleEntries(from startDate: Date, to endDate: Date) -> [LifestyleEntry] {
        let predicate = #Predicate<LifestyleEntry> { entry in
            entry.date >= startDate && entry.date <= endDate
        }
        
        let descriptor = FetchDescriptor<LifestyleEntry>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching lifestyle entries: \(error.localizedDescription)")
            return []
        }
    }
    
    // Basic correlation analysis
    private func performCorrelationAnalysis(
        skinEntries: [SkinEntry],
        lifestyleEntries: [LifestyleEntry],
        healthData: [Date: HealthDayData]
    ) -> [HistoryCorrelationResult] {
        var results: [HistoryCorrelationResult] = []
        
        // Map of dates to severity scores
        let calendar = Calendar.current
        var severityByDate: [Date: Double] = [:]
        
        for entry in skinEntries {
            let dayStart = calendar.startOfDay(for: entry.date)
            severityByDate[dayStart] = entry.severityScore
        }
        
        // Check for dairy correlation
        var dairyCorrelation = HistoryCorrelationResult(
            factor: "Dairy Consumption",
            correlationStrength: 0,
            description: "Insufficient data"
        )
        
        var dairyYesSeverities: [Double] = []
        var dairyNoSeverities: [Double] = []
        
        for entry in lifestyleEntries {
            let dayStart = calendar.startOfDay(for: entry.date)
            
            // Look for severity scores in the next 1-2 days (lag effect)
            for dayOffset in 1...2 {
                if let nextDay = calendar.date(byAdding: .day, value: dayOffset, to: dayStart),
                   let severity = severityByDate[nextDay] {
                    if entry.dairyConsumed {
                        dairyYesSeverities.append(severity)
                    } else {
                        dairyNoSeverities.append(severity)
                    }
                    break
                }
            }
        }
        
        if !dairyYesSeverities.isEmpty && !dairyNoSeverities.isEmpty {
            let dairyYesAvg = dairyYesSeverities.reduce(0, +) / Double(dairyYesSeverities.count)
            let dairyNoAvg = dairyNoSeverities.reduce(0, +) / Double(dairyNoSeverities.count)
            
            let difference = dairyYesAvg - dairyNoAvg
            let normalized = min(abs(difference) / 25.0, 1.0) // Normalize to 0-1 scale
            
            if difference > 10 {
                dairyCorrelation = HistoryCorrelationResult(
                    factor: "Dairy Consumption",
                    correlationStrength: normalized,
                    description: "Skin severity is \(Int(difference)) points higher after consuming dairy"
                )
            } else if difference < -10 {
                // Unusual - dairy seemed to help
                dairyCorrelation = HistoryCorrelationResult(
                    factor: "Dairy Consumption",
                    correlationStrength: normalized,
                    description: "No negative correlation detected with dairy"
                )
            } else {
                dairyCorrelation = HistoryCorrelationResult(
                    factor: "Dairy Consumption",
                    correlationStrength: normalized,
                    description: "Minimal effect from dairy consumption"
                )
            }
        }
        
        results.append(dairyCorrelation)
        
        // Similar analysis for sleep
        var sleepCorrelation = HistoryCorrelationResult(
            factor: "Sleep Duration",
            correlationStrength: 0,
            description: "Insufficient data"
        )
        
        var lowSleepSeverities: [Double] = []
        var highSleepSeverities: [Double] = []
        
        for entry in lifestyleEntries {
            let dayStart = calendar.startOfDay(for: entry.date)
            
            // Look for severity scores in the next 1-2 days (lag effect)
            for dayOffset in 1...2 {
                if let nextDay = calendar.date(byAdding: .day, value: dayOffset, to: dayStart),
                   let severity = severityByDate[nextDay] {
                    if entry.sleepHours < 6.0 {
                        lowSleepSeverities.append(severity)
                    } else if entry.sleepHours >= 7.0 {
                        highSleepSeverities.append(severity)
                    }
                    break
                }
            }
        }
        
        if !lowSleepSeverities.isEmpty && !highSleepSeverities.isEmpty {
            let lowSleepAvg = lowSleepSeverities.reduce(0, +) / Double(lowSleepSeverities.count)
            let highSleepAvg = highSleepSeverities.reduce(0, +) / Double(highSleepSeverities.count)
            
            let difference = lowSleepAvg - highSleepAvg
            let normalized = min(abs(difference) / 25.0, 1.0) // Normalize to 0-1 scale
            
            if difference > 10 {
                sleepCorrelation = HistoryCorrelationResult(
                    factor: "Sleep Duration",
                    correlationStrength: normalized,
                    description: "Skin severity is \(Int(difference)) points higher after insufficient sleep"
                )
            } else {
                sleepCorrelation = HistoryCorrelationResult(
                    factor: "Sleep Duration",
                    correlationStrength: normalized,
                    description: "Minor effect from sleep duration"
                )
            }
        }
        
        results.append(sleepCorrelation)
        
        // Add more correlations here...
        
        // Sort by correlation strength
        return results.sorted(by: { $0.correlationStrength > $1.correlationStrength })
    }
}

// MARK: - Supporting Views and Models

// Renamed to avoid conflicts
struct HistoryCorrelationResult: Identifiable {
    let id = UUID()
    let factor: String
    let correlationStrength: Double // 0-1 scale
    let description: String
}

// Chart container view - renamed to avoid conflicts
struct HistoryChartSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
            
            content
                .frame(height: 220)
                .padding(.horizontal, 8)
        }
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// Correlation analysis section - renamed to avoid conflicts
struct HistoryCorrelationSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
            
            content
                .padding(.horizontal, 8)
        }
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// Severity chart implementation - renamed to avoid conflicts
struct HistorySeverityChart: View {
    let skinEntries: [SkinEntry]
    
    var body: some View {
        if #available(iOS 16.0, *) {
            Chart {
                ForEach(skinEntries) { entry in
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Severity", entry.severityScore)
                    )
                    .foregroundStyle(Color.red.gradient)
                    
                    PointMark(
                        x: .value("Date", entry.date),
                        y: .value("Severity", entry.severityScore)
                    )
                    .foregroundStyle(Color.red)
                }
            }
            .chartYScale(domain: 0...100)
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
        } else {
            // Fallback for iOS 15
            Text("Charts available in iOS 16+")
                .font(.callout)
                .foregroundColor(.gray)
        }
    }
}

// New time series implementation for affected areas - renamed to avoid conflicts
struct HistoryAffectedAreasTimeSeriesChart: View {
    let skinEntries: [SkinEntry]
    
    // Extract time series data for each region
    private var timeSeriesData: [String: [(date: Date, severity: Double)]] {
        var result: [String: [(date: Date, severity: Double)]] = [:]
        
        // Initialize with all common regions
        let commonRegions = ["Forehead", "Cheeks", "Chin", "Nose"]
        for region in commonRegions {
            result[region] = []
        }
        
        for entry in skinEntries {
            guard let regions = entry.regions else { continue }
            
            for region in regions {
                if result[region.name] == nil {
                    result[region.name] = []
                }
                
                result[region.name]?.append((entry.date, region.severity * 100))
            }
        }
        
        // Sort each region's data by date
        for (region, _) in result {
            result[region]?.sort { $0.date < $1.date }
        }
        
        return result
    }
    
    var body: some View {
        if #available(iOS 16.0, *) {
            Chart {
                ForEach(Array(timeSeriesData.keys), id: \.self) { regionName in
                    if let regionData = timeSeriesData[regionName], !regionData.isEmpty {
                        ForEach(0..<regionData.count, id: \.self) { index in
                            let dataPoint = regionData[index]
                            LineMark(
                                x: .value("Date", dataPoint.date),
                                y: .value("Severity", dataPoint.severity)
                            )
                            .foregroundStyle(by: .value("Region", regionName))
                            
                            PointMark(
                                x: .value("Date", dataPoint.date),
                                y: .value("Severity", dataPoint.severity)
                            )
                            .foregroundStyle(by: .value("Region", regionName))
                        }
                    }
                }
            }
            .chartYScale(domain: 0...100)
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            .chartForegroundStyleScale([
                "Forehead": Color.blue,
                "Cheeks": Color.red,
                "Chin": Color.green,
                "Nose": Color.orange,
                "Eyes": Color.purple
            ])
        } else {
            // Fallback for iOS 15
            VStack {
                Text("Charts available in iOS 16+")
                    .font(.callout)
                    .foregroundColor(.gray)
                
                // Basic legend
                HStack(spacing: 16) {
                    ForEach(["Forehead", "Cheeks", "Chin", "Nose"], id: \.self) { regionName in
                        HistoryLegendItem(color: colorForRegion(regionName), label: regionName)
                    }
                }
                .padding(.top, 8)
            }
        }
    }
    
    private func colorForRegion(_ region: String) -> Color {
        switch region {
        case "Forehead":
            return .blue
        case "Cheeks":
            return .red
        case "Chin":
            return .green
        case "Nose":
            return .orange
        case "Eyes":
            return .purple
        default:
            return .gray
        }
    }
}

// Legend item - renamed to avoid conflicts
struct HistoryLegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            
            Text(label)
                .font(.caption)
        }
    }
}

// Correlation view - renamed to avoid conflicts
struct HistoryCorrelationView: View {
    let correlations: [HistoryCorrelationResult]
    
    var body: some View {
        VStack(spacing: 16) {
            if correlations.isEmpty {
                Text("Not enough data to analyse correlations")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ForEach(correlations) { correlation in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(correlation.factor)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            // Correlation strength indicator
                            HStack(spacing: 2) {
                                ForEach(0..<5, id: \.self) { index in
                                    Circle()
                                        .fill(index < Int(correlation.correlationStrength * 5) ? Color.blue : Color.gray.opacity(0.3))
                                        .frame(width: 8, height: 8)
                                }
                            }
                        }
                        
                        Text(correlation.description)
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        if correlation.correlationStrength > 0 {
                            ProgressView(value: correlation.correlationStrength)
                                .progressViewStyle(LinearProgressViewStyle(tint: correlationColor(strength: correlation.correlationStrength)))
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    private func correlationColor(strength: Double) -> Color {
        switch strength {
        case 0..<0.3: return .blue
        case 0.3..<0.6: return .orange
        default: return .red
        }
    }
}
