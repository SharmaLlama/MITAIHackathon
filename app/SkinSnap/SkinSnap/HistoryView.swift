import SwiftUI
import SwiftData
import Charts
struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var healthKitManager: HealthKitManager
    
    // Using SwiftData for direct data access
    // Instead of using @Query which might be causing issues, we'll fetch manually
    @State private var skinEntries: [SkinEntry] = []
    @State private var lifestyleEntries: [LifestyleEntry] = []
    
    @State private var selectedTimeRange: TimeRange = .week
    @State private var healthData: [Date: HealthDayData] = [:]
    @State private var correlationResults: [CorrelationResult] = []
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
                        Text("Week").tag(TimeRange.week)
                        Text("Month").tag(TimeRange.month)
                        Text("3 Months").tag(TimeRange.threeMonths)
                        Text("6 Months").tag(TimeRange.sixMonths)
                        Text("Year").tag(TimeRange.year)
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
                        ChartSection(title: "Skin Severity Trend") {
                            SeverityChart(skinEntries: skinEntries)
                        }
                        
                        // Affected Areas Chart - now a time series
                        ChartSection(title: "Affected Areas Over Time") {
                            AffectedAreasTimeSeriesChart(skinEntries: skinEntries)
                        }
                        
                        // Correlation Analysis
                        CorrelationSection(title: "Potential Triggers") {
                            CorrelationView(correlations: correlationResults)
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
        skinEntries = SkinEntry.entriesInRange(
            modelContext: modelContext,
            from: startDate,
            to: endDate
        )
        
        lifestyleEntries = LifestyleEntry.entriesInRange(
            modelContext: modelContext,
            from: startDate,
            to: endDate
        )
        
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
    
    // Basic correlation analysis
    private func performCorrelationAnalysis(
        skinEntries: [SkinEntry],
        lifestyleEntries: [LifestyleEntry],
        healthData: [Date: HealthDayData]
    ) -> [CorrelationResult] {
        var results: [CorrelationResult] = []
        
        // Map of dates to severity scores
        let calendar = Calendar.current
        var severityByDate: [Date: Double] = [:]
        
        for entry in skinEntries {
            let dayStart = calendar.startOfDay(for: entry.date)
            severityByDate[dayStart] = entry.severityScore
        }
        
        // Check for dairy correlation
        var dairyCorrelation = CorrelationResult(
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
                dairyCorrelation = CorrelationResult(
                    factor: "Dairy Consumption",
                    correlationStrength: normalized,
                    description: "Skin severity is \(Int(difference)) points higher after consuming dairy"
                )
            } else if difference < -10 {
                // Unusual - dairy seemed to help
                dairyCorrelation = CorrelationResult(
                    factor: "Dairy Consumption",
                    correlationStrength: normalized,
                    description: "No negative correlation detected with dairy"
                )
            } else {
                dairyCorrelation = CorrelationResult(
                    factor: "Dairy Consumption",
                    correlationStrength: normalized,
                    description: "Minimal effect from dairy consumption"
                )
            }
        }
        
        results.append(dairyCorrelation)
        
        // Similar analysis for sleep
        var sleepCorrelation = CorrelationResult(
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
                sleepCorrelation = CorrelationResult(
                    factor: "Sleep Duration",
                    correlationStrength: normalized,
                    description: "Skin severity is \(Int(difference)) points higher after insufficient sleep"
                )
            } else {
                sleepCorrelation = CorrelationResult(
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

// MARK: - Supporting Views

// Chart container view
struct ChartSection<Content: View>: View {
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

// Correlation analysis section
struct CorrelationSection<Content: View>: View {
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

// Severity chart implementation
struct SeverityChart: View {
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

// New time series implementation for affected areas
struct AffectedAreasTimeSeriesChart: View {
    let skinEntries: [SkinEntry]
    
    // Extract time series data for each region
    private var timeSeriesData: [String: [(date: Date, severity: Double)]] {
        var result: [String: [(date: Date, severity: Double)]] = [:]
        
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
                    if let regionData = timeSeriesData[regionName] {
                        ForEach(regionData, id: \.date) { dataPoint in
                            LineMark(
                                x: .value("Date", dataPoint.date),
                                y: .value("Severity", dataPoint.severity)
                            )
                            .foregroundStyle(colorForRegion(regionName))
                            
                            PointMark(
                                x: .value("Date", dataPoint.date),
                                y: .value("Severity", dataPoint.severity)
                            )
                            .foregroundStyle(colorForRegion(regionName))
                        }
                        .interpolationMethod(.catmullRom)
                        .symbol(.circle)
                        .symbolSize(30)
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
            .chartLegend(position: .bottom) {
                HStack(spacing: 16) {
                    ForEach(Array(timeSeriesData.keys).sorted(), id: \.self) { regionName in
                        LegendItem(color: colorForRegion(regionName), label: regionName)
                    }
                }
            }
        } else {
            // Fallback for iOS 15
            VStack {
                Text("Charts available in iOS 16+")
                    .font(.callout)
                    .foregroundColor(.gray)
                
                // Basic legend
                HStack(spacing: 16) {
                    ForEach(["Forehead", "Cheeks", "Chin", "Nose"], id: \.self) { regionName in
                        LegendItem(color: colorForRegion(regionName), label: regionName)
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

struct LegendItem: View {
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

// Correlation view
struct CorrelationView: View {
    let correlations: [CorrelationResult]
    
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

// MARK: - Supporting Models

enum TimeRange {
    case week, month, threeMonths, sixMonths, year
}

struct RegionData: Identifiable {
    let id = UUID()
    let name: String
    let severity: Double
}

struct CorrelationResult: Identifiable {
    let id = UUID()
    let factor: String
    let correlationStrength: Double // 0-1 scale
    let description: String
}

// MARK: - Supporting Views

// Chart container view
struct ChartSection<Content: View>: View {
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

// Correlation analysis section
struct CorrelationSection<Content: View>: View {
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

// Severity chart implementation
struct SeverityChart: View {
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

// Affected areas chart
struct AffectedAreasChart: View {
    let skinEntries: [SkinEntry]
    
    // Extract region data from SwiftData entries
    var regionData: [RegionData] {
        // Get the latest entry with regions
        guard let latestEntry = skinEntries.sorted(by: { $0.date > $1.date }).first,
              let regions = latestEntry.regions, !regions.isEmpty else {
            // Fallback to placeholder data if no regions are available
            return [
                RegionData(name: "Forehead", severity: 65),
                RegionData(name: "Cheeks", severity: 45),
                RegionData(name: "Chin", severity: 78),
                RegionData(name: "Nose", severity: 32)
            ]
        }
        
        // Convert RegionSeverity to RegionData
        return regions.map { region in
            RegionData(name: region.name, severity: region.severity * 100)
        }
    }
    
    var body: some View {
        if #available(iOS 16.0, *) {
            Chart {
                ForEach(regionData) { region in
                    BarMark(
                        x: .value("Region", region.name),
                        y: .value("Severity", region.severity)
                    )
                    .foregroundStyle(Color.orange.gradient)
                }
            }
            .chartYScale(domain: 0...100)
        } else {
            // Fallback for iOS 15
            HStack {
                ForEach(regionData) { region in
                    VStack {
                        Spacer()
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.orange)
                            .frame(width: 30, height: CGFloat(region.severity) * 1.8)
                        
                        Text(region.name)
                            .font(.caption)
                            .frame(width: 60)
                            .multilineTextAlignment(.center)
                    }
                }
                Spacer()
            }
            .padding(.horizontal)
        }
    }
}

// Correlation view
struct CorrelationView: View {
    let correlations: [CorrelationResult]
    
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

// MARK: - Supporting Models

enum TimeRange {
    case week, month, threeMonths, sixMonths, year
}

struct RegionData: Identifiable {
    let id = UUID()
    let name: String
    let severity: Double
}

struct CorrelationResult: Identifiable {
    let id = UUID()
    let factor: String
    let correlationStrength: Double // 0-1 scale
    let description: String
}
