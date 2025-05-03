import SwiftUI
import SwiftData
import Charts

// Define TimeRange enum directly in this file to avoid scope issues
enum HistoryTimeRange {
    case week, month, threeMonths, sixMonths, year
}

// MARK: - Enhanced Correlation Analysis - Supporting Types

// Structure for holding factor analysis results
struct FactorAnalysisResult {
    let factorName: String
    let correlation: Double // -1.0 to 1.0, where positive means better skin health
    let confidence: Double // 0.0 to 1.0
    let dataPoints: Int
    let avgHealthWithFactor: Double
    let avgHealthWithoutFactor: Double
    let description: String
    let impactType: ImpactType
    
    // Average health difference with vs without the factor
    var healthDifference: Double {
        return avgHealthWithFactor - avgHealthWithoutFactor
    }
    
    // Absolute value of correlation for sorting
    var absoluteCorrelation: Double {
        return abs(correlation)
    }
    
    enum ImpactType {
        case positive // Factor is associated with better skin health
        case negative // Factor is associated with worse skin health
        case neutral // No clear impact
        
        var symbol: String {
            switch self {
            case .positive: return "arrow.up.circle.fill"
            case .negative: return "arrow.down.circle.fill"
            case .neutral: return "equal.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .positive: return .green
            case .negative: return .red
            case .neutral: return .gray
            }
        }
    }
}

// Time window for analysis
enum AnalysisTimeWindow {
    case immediate // Same day
    case shortTerm // 1-2 days
    case mediumTerm // 3-5 days
    case longTerm // 6-14 days
    
    var description: String {
        switch self {
        case .immediate: return "same day"
        case .shortTerm: return "1-2 days"
        case .mediumTerm: return "3-5 days"
        case .longTerm: return "6-14 days"
        }
    }
    
    var dayRange: ClosedRange<Int> {
        switch self {
        case .immediate: return 0...0
        case .shortTerm: return 1...2
        case .mediumTerm: return 3...5
        case .longTerm: return 6...14
        }
    }
}

// MARK: - HistoryCorrelationResult

// Renamed to avoid conflicts
struct HistoryCorrelationResult: Identifiable {
    let id = UUID()
    let factor: String
    let correlationStrength: Double // 0-1 scale
    let description: String
}

// MARK: - Face Heatmap Components

struct FaceHeatmapView: View {
    let skinEntries: [SkinEntry]
    let timeRange: HistoryTimeRange
    
    @State private var currentTimeIndex: Int = 0
    @State private var showingTimeSlider: Bool = false
    
    // Define the face regions
    private let regions = ["Forehead", "Cheeks", "Chin", "Nose"]
    
    // Get entries grouped by time period
    private var entriesByTimePeriod: [[SkinEntry]] {
        guard !skinEntries.isEmpty else { return [] }
        
        let sortedEntries = skinEntries.sorted { $0.date < $1.date }
        let calendar = Calendar.current
        
        switch timeRange {
        case .week:
            // Group by day
            return groupEntriesByTimeUnit(entries: sortedEntries) { date in
                calendar.startOfDay(for: date)
            }
        case .month:
            // Group by 3-day periods
            return groupEntriesByTimeUnit(entries: sortedEntries) { date in
                let components = calendar.dateComponents([.year, .month, .day], from: date)
                let day = components.day ?? 1
                let period = (day - 1) / 3
                var newComponents = DateComponents()
                newComponents.year = components.year
                newComponents.month = components.month
                newComponents.day = period * 3 + 1
                return calendar.date(from: newComponents) ?? date
            }
        case .threeMonths, .sixMonths:
            // Group by week
            return groupEntriesByTimeUnit(entries: sortedEntries) { date in
                let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
                return calendar.date(from: components) ?? date
            }
        case .year:
            // Group by month
            return groupEntriesByTimeUnit(entries: sortedEntries) { date in
                let components = calendar.dateComponents([.year, .month], from: date)
                return calendar.date(from: components) ?? date
            }
        }
    }
    
    // Group entries by a time unit using the provided key generator
    private func groupEntriesByTimeUnit(entries: [SkinEntry], keyForDate: (Date) -> Date) -> [[SkinEntry]] {
        var groups: [Date: [SkinEntry]] = [:]
        
        for entry in entries {
            let key = keyForDate(entry.date)
            if groups[key] == nil {
                groups[key] = []
            }
            groups[key]?.append(entry)
        }
        
        // Sort by date and return values
        return groups.sorted { $0.key < $1.key }.map { $0.value }
    }
    
    // Get time period label
    private var timePeriodLabel: String {
        guard !entriesByTimePeriod.isEmpty, currentTimeIndex < entriesByTimePeriod.count else {
            return "No data"
        }
        
        let entries = entriesByTimePeriod[currentTimeIndex]
        guard let firstDate = entries.first?.date, let lastDate = entries.last?.date else {
            return "No data"
        }
        
        let formatter = DateFormatter()
        
        switch timeRange {
        case .week:
            formatter.dateFormat = "MMM d"
            return formatter.string(from: firstDate)
        case .month:
            formatter.dateFormat = "MMM d"
            return "\(formatter.string(from: firstDate)) - \(formatter.string(from: lastDate))"
        case .threeMonths, .sixMonths:
            formatter.dateFormat = "MMM d"
            return "Week of \(formatter.string(from: firstDate))"
        case .year:
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: firstDate)
        }
    }
    
    // Calculate region severity for the current time period
    private func severityForRegion(_ regionName: String) -> Double {
        guard !entriesByTimePeriod.isEmpty, currentTimeIndex < entriesByTimePeriod.count else {
            return 0
        }
        
        let entries = entriesByTimePeriod[currentTimeIndex]
        var severitySum: Double = 0
        var count: Int = 0
        
        for entry in entries {
            if let regions = entry.regions {
                if let region = regions.first(where: { $0.name == regionName }) {
                    severitySum += region.severity
                    count += 1
                }
            }
        }
        
        return count > 0 ? severitySum / Double(count) : 0
    }
    
    // Map severity to color
    private func colorForSeverity(_ severity: Double) -> Color {
        // Convert severity (0-1) to heatmap color
        let normalizedSeverity = min(max(severity, 0), 1)
        
        if normalizedSeverity < 0.2 {
            return Color.green.opacity(0.1 + normalizedSeverity * 0.5)
        } else if normalizedSeverity < 0.5 {
            return Color.yellow.opacity(0.3 + normalizedSeverity * 0.5)
        } else if normalizedSeverity < 0.8 {
            return Color.orange.opacity(0.3 + normalizedSeverity * 0.5)
        } else {
            return Color.red.opacity(0.3 + normalizedSeverity * 0.5)
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if entriesByTimePeriod.isEmpty {
                Text("No data available for this time range")
                    .foregroundColor(.gray)
                    .frame(height: 220)
            } else {
                // Time period navigation
                HStack {
                    Button(action: {
                        withAnimation {
                            currentTimeIndex = max(0, currentTimeIndex - 1)
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(currentTimeIndex > 0 ? .blue : .gray)
                    }
                    .disabled(currentTimeIndex <= 0)
                    
                    Spacer()
                    
                    Text(timePeriodLabel)
                        .font(.headline)
                        .onTapGesture {
                            withAnimation {
                                showingTimeSlider.toggle()
                            }
                        }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            currentTimeIndex = min(entriesByTimePeriod.count - 1, currentTimeIndex + 1)
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(currentTimeIndex < entriesByTimePeriod.count - 1 ? .blue : .gray)
                    }
                    .disabled(currentTimeIndex >= entriesByTimePeriod.count - 1)
                }
                .padding(.horizontal)
                
                // Optional time slider
                if showingTimeSlider && entriesByTimePeriod.count > 1 {
                    VStack(spacing: 2) {
                        Slider(value: Binding(
                            get: { Double(self.currentTimeIndex) },
                            set: { self.currentTimeIndex = Int($0) }
                        ), in: 0...Double(entriesByTimePeriod.count - 1), step: 1)
                        
                        // Timeline labels
                        HStack {
                            Text(formatDate(entriesByTimePeriod.first?.first?.date))
                                .font(.caption)
                            
                            Spacer()
                            
                            Text(formatDate(entriesByTimePeriod.last?.last?.date))
                                .font(.caption)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Face heatmap visualization
                ZStack {
                    // Base face outline
                    FaceOutlineView()
                        .stroke(Color.gray, lineWidth: 2)
                        .frame(width: 260, height: 300)
                    
                    // Forehead region
                    ForeheadView()
                        .fill(colorForSeverity(severityForRegion("Forehead")))
                    
                    // Left cheek region
                    LeftCheekView()
                        .fill(colorForSeverity(severityForRegion("Cheeks")))
                    
                    // Right cheek region
                    RightCheekView()
                        .fill(colorForSeverity(severityForRegion("Cheeks")))
                    
                    // Nose region
                    NoseView()
                        .fill(colorForSeverity(severityForRegion("Nose")))
                    
                    // Chin region
                    ChinView()
                        .fill(colorForSeverity(severityForRegion("Chin")))
                }
                .frame(height: 220)
                
                // Region legend
                VStack(spacing: 12) {
                    ForEach(regions, id: \.self) { region in
                        let severity = severityForRegion(region)
                        HStack {
                            Circle()
                                .fill(colorForSeverity(severity))
                                .frame(width: 12, height: 12)
                            
                            Text(region)
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text("\(Int(severity * 100))%")
                                .font(.subheadline)
                                .foregroundColor(colorForSeverity(severity))
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Face Region Views

// Base face outline
struct FaceOutlineView: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        
        var path = Path()
        
        // Draw face outline (oval shape)
        path.addEllipse(in: CGRect(x: width * 0.1, y: height * 0.05, width: width * 0.8, height: height * 0.9))
        
        return path
    }
}

// Forehead region
struct ForeheadView: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        
        var path = Path()
        
        // Draw forehead as upper part of the face
        path.move(to: CGPoint(x: width * 0.1, y: height * 0.3))
        path.addLine(to: CGPoint(x: width * 0.1, y: height * 0.05))
        path.addCurve(
            to: CGPoint(x: width * 0.9, y: height * 0.05),
            control1: CGPoint(x: width * 0.3, y: height * -0.1),
            control2: CGPoint(x: width * 0.7, y: height * -0.1)
        )
        path.addLine(to: CGPoint(x: width * 0.9, y: height * 0.3))
        path.addCurve(
            to: CGPoint(x: width * 0.1, y: height * 0.3),
            control1: CGPoint(x: width * 0.7, y: height * 0.25),
            control2: CGPoint(x: width * 0.3, y: height * 0.25)
        )
        path.closeSubpath()
        
        return path
    }
}

// Left cheek region
struct LeftCheekView: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        
        var path = Path()
        
        // Draw left cheek
        path.move(to: CGPoint(x: width * 0.1, y: height * 0.3))
        path.addLine(to: CGPoint(x: width * 0.1, y: height * 0.7))
        path.addCurve(
            to: CGPoint(x: width * 0.35, y: height * 0.65),
            control1: CGPoint(x: width * 0.2, y: height * 0.7),
            control2: CGPoint(x: width * 0.25, y: height * 0.65)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.35, y: height * 0.35),
            control1: CGPoint(x: width * 0.35, y: height * 0.55),
            control2: CGPoint(x: width * 0.35, y: height * 0.45)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.1, y: height * 0.3),
            control1: CGPoint(x: width * 0.25, y: height * 0.35),
            control2: CGPoint(x: width * 0.2, y: height * 0.3)
        )
        path.closeSubpath()
        
        return path
    }
}

// Right cheek region
struct RightCheekView: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        
        var path = Path()
        
        // Draw right cheek (mirror of left)
        path.move(to: CGPoint(x: width * 0.9, y: height * 0.3))
        path.addLine(to: CGPoint(x: width * 0.9, y: height * 0.7))
        path.addCurve(
            to: CGPoint(x: width * 0.65, y: height * 0.65),
            control1: CGPoint(x: width * 0.8, y: height * 0.7),
            control2: CGPoint(x: width * 0.75, y: height * 0.65)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.65, y: height * 0.35),
            control1: CGPoint(x: width * 0.65, y: height * 0.55),
            control2: CGPoint(x: width * 0.65, y: height * 0.45)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.9, y: height * 0.3),
            control1: CGPoint(x: width * 0.75, y: height * 0.35),
            control2: CGPoint(x: width * 0.8, y: height * 0.3)
        )
        path.closeSubpath()
        
        return path
    }
}

// Nose region
struct NoseView: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        
        var path = Path()
        
        // Draw nose in the center
        path.move(to: CGPoint(x: width * 0.4, y: height * 0.35))
        path.addLine(to: CGPoint(x: width * 0.4, y: height * 0.55))
        path.addCurve(
            to: CGPoint(x: width * 0.6, y: height * 0.55),
            control1: CGPoint(x: width * 0.45, y: height * 0.6),
            control2: CGPoint(x: width * 0.55, y: height * 0.6)
        )
        path.addLine(to: CGPoint(x: width * 0.6, y: height * 0.35))
        path.addCurve(
            to: CGPoint(x: width * 0.4, y: height * 0.35),
            control1: CGPoint(x: width * 0.55, y: height * 0.35),
            control2: CGPoint(x: width * 0.45, y: height * 0.35)
        )
        path.closeSubpath()
        
        return path
    }
}

// Chin region
struct ChinView: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        
        var path = Path()
        
        // Draw chin as bottom part of face
        path.move(to: CGPoint(x: width * 0.35, y: height * 0.65))
        path.addCurve(
            to: CGPoint(x: width * 0.65, y: height * 0.65),
            control1: CGPoint(x: width * 0.45, y: height * 0.65),
            control2: CGPoint(x: width * 0.55, y: height * 0.65)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.7, y: height * 0.9),
            control1: CGPoint(x: width * 0.68, y: height * 0.7),
            control2: CGPoint(x: width * 0.7, y: height * 0.8)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height * 0.95),
            control1: CGPoint(x: width * 0.65, y: height * 0.95),
            control2: CGPoint(x: width * 0.6, y: height * 0.95)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.3, y: height * 0.9),
            control1: CGPoint(x: width * 0.4, y: height * 0.95),
            control2: CGPoint(x: width * 0.35, y: height * 0.95)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.35, y: height * 0.65),
            control1: CGPoint(x: width * 0.3, y: height * 0.8),
            control2: CGPoint(x: width * 0.32, y: height * 0.7)
        )
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Affected Areas Visualization View

struct AffectedAreasVisualizationView: View {
    let skinEntries: [SkinEntry]
    let timeRange: HistoryTimeRange
    @State private var selectedVisualization = 0
    
    var body: some View {
        VStack(spacing: 8) {
            // Visualization type selector
            Picker("Visualization", selection: $selectedVisualization) {
                Text("Chart").tag(0)
                Text("Face Map").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // Show either the chart or face heatmap
            if selectedVisualization == 0 {
                HistoryAffectedAreasTimeSeriesChart(skinEntries: skinEntries)
            } else {
                FaceHeatmapView(skinEntries: skinEntries, timeRange: timeRange)
            }
        }
    }
}

// MARK: - Main History View

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
                        
                        // Skin Health Chart
                        HistoryChartSection(title: "Skin Health Trend") {
                            HistorySkinHealthChart(skinEntries: skinEntries)
                        }
                        
                        // Affected Areas Chart and Face Heatmap
                        HistoryChartSection(title: "Affected Areas Over Time") {
                            AffectedAreasVisualizationView(skinEntries: skinEntries, timeRange: selectedTimeRange)
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
            self.correlationResults = self.performEnhancedCorrelationAnalysis(
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
        
        // Map of dates to skin health scores
        let calendar = Calendar.current
        var healthByDate: [Date: Double] = [:]
        
        for entry in skinEntries {
            let dayStart = calendar.startOfDay(for: entry.date)
            healthByDate[dayStart] = entry.severityScore
        }
        
        // Check for dairy correlation
        var dairyCorrelation = HistoryCorrelationResult(
            factor: "Dairy Consumption",
            correlationStrength: 0,
            description: "Insufficient data"
        )
        
        var dairyYesHealth: [Double] = []
        var dairyNoHealth: [Double] = []
        
        for entry in lifestyleEntries {
            let dayStart = calendar.startOfDay(for: entry.date)
            
            // Look for health scores in the next 1-2 days (lag effect)
            for dayOffset in 1...2 {
                if let nextDay = calendar.date(byAdding: .day, value: dayOffset, to: dayStart),
                   let health = healthByDate[nextDay] {
                    if entry.dairyConsumed {
                        dairyYesHealth.append(health)
                    } else {
                        dairyNoHealth.append(health)
                    }
                    break
                }
            }
        }
        
        if !dairyYesHealth.isEmpty && !dairyNoHealth.isEmpty {
            let dairyYesAvg = dairyYesHealth.reduce(0, +) / Double(dairyYesHealth.count)
            let dairyNoAvg = dairyNoHealth.reduce(0, +) / Double(dairyNoHealth.count)
            
            let difference = dairyNoAvg - dairyYesAvg // Reversed since higher is better
            let normalized = min(abs(difference) / 25.0, 1.0) // Normalize to 0-1 scale
            
            if difference > 10 {
                dairyCorrelation = HistoryCorrelationResult(
                    factor: "Dairy Consumption",
                    correlationStrength: normalized,
                    description: "Skin health is \(Int(difference)) points lower after consuming dairy"
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
        
        var lowSleepHealth: [Double] = []
        var highSleepHealth: [Double] = []
        
        for entry in lifestyleEntries {
            let dayStart = calendar.startOfDay(for: entry.date)
            
            // Look for health scores in the next 1-2 days (lag effect)
            for dayOffset in 1...2 {
                if let nextDay = calendar.date(byAdding: .day, value: dayOffset, to: dayStart),
                   let health = healthByDate[nextDay] {
                    if entry.sleepHours < 6.0 {
                        lowSleepHealth.append(health)
                    } else if entry.sleepHours >= 7.0 {
                        highSleepHealth.append(health)
                    }
                    break
                }
            }
        }
        
        if !lowSleepHealth.isEmpty && !highSleepHealth.isEmpty {
            let lowSleepAvg = lowSleepHealth.reduce(0, +) / Double(lowSleepHealth.count)
            let highSleepAvg = highSleepHealth.reduce(0, +) / Double(highSleepHealth.count)
            
            let difference = highSleepAvg - lowSleepAvg // Higher sleep is better
            let normalized = min(abs(difference) / 25.0, 1.0) // Normalize to 0-1 scale
            
            if difference > 10 {
                sleepCorrelation = HistoryCorrelationResult(
                    factor: "Sleep Duration",
                    correlationStrength: normalized,
                    description: "Skin health is \(Int(difference)) points lower after insufficient sleep"
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
    
    // MARK: - Enhanced Correlation Analysis Methods
    
    // Enhanced version of performCorrelationAnalysis
    private func performEnhancedCorrelationAnalysis(
        skinEntries: [SkinEntry],
        lifestyleEntries: [LifestyleEntry],
        healthData: [Date: HealthDayData]
    ) -> [HistoryCorrelationResult] {
        
        // Skip analysis if not enough data
        if skinEntries.count < 3 || lifestyleEntries.count < 3 {
            return [
                HistoryCorrelationResult(
                    factor: "Insufficient Data",
                    correlationStrength: 0,
                    description: "At least 3 days of data needed for meaningful analysis."
                )
            ]
        }
        
        let calendar = Calendar.current
        
        // Group skin entries by date for easier lookup
        var healthByDate: [Date: Double] = [:]
        for entry in skinEntries {
            let dayStart = calendar.startOfDay(for: entry.date)
            healthByDate[dayStart] = entry.severityScore
        }
        
        // All factors to analyze - add any new factors here
        let factorsToAnalyze: [(name: String, extractor: (LifestyleEntry) -> Bool)] = [
            ("Dairy Consumption", { $0.dairyConsumed }),
            ("Sugar Consumption", { $0.sugarConsumed }),
            ("Alcohol Consumption", { $0.alcoholConsumed }),
            ("Fast Food", { $0.fastFoodConsumed }),
            ("High Protein Diet", { $0.highProteinMeal }),
            ("Sunscreen Use", { $0.usedSunscreen }),
            ("Makeup Use", { $0.usedMakeup }),
            ("Face Wash Use", { $0.usedFaceWash }),
            ("Moisturizer Use", { $0.usedMoisturizer }),
            ("Acne Treatment", { $0.usedAcneTreatment }),
            ("Fresh Pillowcase", { $0.changedPillowcase }),
            ("Travel", { $0.traveledRecently }),
            ("Climate Change", { $0.climateChange })
        ]
        
        // Continuous factors for quantitative analysis
        let continuousFactors: [(name: String, extractor: (LifestyleEntry) -> Double, threshold: Double, comparison: (Double, Double) -> Bool)] = [
            ("Low Sleep", { $0.sleepHours }, 7.0, { $0 < $1 }), // Less than 7 hours
            ("High Sleep", { $0.sleepHours }, 8.0, { $0 >= $1 }), // 8 or more hours
            ("High Stress", { Double($0.stressLevel) }, 3.0, { $0 > $1 }), // Higher than 3
            ("Low Water Intake", { Double($0.waterIntake) }, 6.0, { $0 < $1 }), // Less than 6 glasses
            ("High Water Intake", { Double($0.waterIntake) }, 8.0, { $0 >= $1 }), // 8 or more glasses
            ("Many Fruits & Veggies", { Double($0.fruitsAndVeggiesServings) }, 4.0, { $0 >= $1 }), // 4 or more servings
            ("High Mood", { Double($0.moodRating) }, 4.0, { $0 >= $1 }), // 4 or higher (good mood)
            ("High Anxiety", { Double($0.anxietyLevel) }, 3.0, { $0 >= $1 }), // 3 or higher (anxious)
            ("Outdoor Exposure", { $0.outdoorHours }, 2.0, { $0 > $1 }), // More than 2 hours outside
            ("High Sun Exposure", { Double($0.sunExposureLevel) }, 3.0, { $0 >= $1 }) // 3 or higher sun exposure
        ]
        
        // Time windows to analyze (to detect delayed effects)
        let timeWindows: [AnalysisTimeWindow] = [.shortTerm, .mediumTerm]
        
        // Analyze each factor across time windows
        var factorResults: [FactorAnalysisResult] = []
        
        // First, analyze binary factors
        for (factorName, factorExtractor) in factorsToAnalyze {
            for timeWindow in timeWindows {
                let result = analyzeFactorAcrossTimeWindow(
                    factorName: factorName,
                    timeWindow: timeWindow,
                    healthByDate: healthByDate,
                    lifestyleEntries: lifestyleEntries,
                    factorExtractor: factorExtractor
                )
                
                if result.dataPoints >= 3 && abs(result.correlation) >= 0.15 {
                    factorResults.append(result)
                }
            }
        }
        
        // Then, analyze continuous factors
        for (factorName, factorExtractor, threshold, comparison) in continuousFactors {
            for timeWindow in timeWindows {
                let result = analyzeContinuousFactorAcrossTimeWindow(
                    factorName: factorName,
                    timeWindow: timeWindow,
                    healthByDate: healthByDate,
                    lifestyleEntries: lifestyleEntries,
                    factorExtractor: factorExtractor,
                    threshold: threshold,
                    comparison: comparison
                )
                
                if result.dataPoints >= 3 && abs(result.correlation) >= 0.15 {
                    factorResults.append(result)
                }
            }
        }
        
        // Analyze multi-factor combinations
        if lifestyleEntries.count >= 5 {
            let stressAndDairyResult = analyzeMultiFactorCombination(
                factorName: "Stress + Dairy",
                timeWindow: .shortTerm,
                healthByDate: healthByDate,
                lifestyleEntries: lifestyleEntries,
                factorCondition: { entry in
                    entry.stressLevel >= 4 && entry.dairyConsumed
                }
            )
            
            if stressAndDairyResult.dataPoints >= 2 && abs(stressAndDairyResult.correlation) >= 0.2 {
                factorResults.append(stressAndDairyResult)
            }
            
            let sugarAndLowSleepResult = analyzeMultiFactorCombination(
                factorName: "Sugar + Low Sleep",
                timeWindow: .shortTerm,
                healthByDate: healthByDate,
                lifestyleEntries: lifestyleEntries,
                factorCondition: { entry in
                    entry.sugarConsumed && entry.sleepHours < 6.5
                }
            )
            
            if sugarAndLowSleepResult.dataPoints >= 2 && abs(sugarAndLowSleepResult.correlation) >= 0.2 {
                factorResults.append(sugarAndLowSleepResult)
            }
        }
        
        // Sort results by correlation strength and limit to top findings
        factorResults.sort { $0.absoluteCorrelation > $1.absoluteCorrelation }
        let topResults = Array(factorResults.prefix(5))
        
        // Convert to HistoryCorrelationResult format
        return topResults.map { result in
            let description: String
            let direction = result.correlation >= 0 ? "improved" : "worsened"
            let timeframe = result.impactType == .neutral ? "" : "after \(result.healthDifference) points \(direction)"
            
            if result.impactType == .positive {
                description = "\(result.factorName) is associated with better skin health \(timeframe)"
            } else if result.impactType == .negative {
                description = "\(result.factorName) is associated with reduced skin health \(timeframe)"
            } else {
                description = result.description
            }
            
            return HistoryCorrelationResult(
                factor: result.factorName,
                correlationStrength: abs(result.correlation),
                description: description
            )
        }
    }
    
    // Analyze a single factor across a time window
    private func analyzeFactorAcrossTimeWindow(
        factorName: String,
        timeWindow: AnalysisTimeWindow,
        healthByDate: [Date: Double],
        lifestyleEntries: [LifestyleEntry],
        factorExtractor: (LifestyleEntry) -> Bool
    ) -> FactorAnalysisResult {
        let calendar = Calendar.current
        
        var factorActiveHealth: [Double] = []
        var factorInactiveHealth: [Double] = []
        
        for entry in lifestyleEntries {
            let factorPresent = factorExtractor(entry)
            let entryDayStart = calendar.startOfDay(for: entry.date)
            
            // Look for health scores in the given time window
            for dayOffset in timeWindow.dayRange {
                if let futureDay = calendar.date(byAdding: .day, value: dayOffset, to: entryDayStart),
                   let healthScore = healthByDate[futureDay] {
                    
                    if factorPresent {
                        factorActiveHealth.append(healthScore)
                    } else {
                        factorInactiveHealth.append(healthScore)
                    }
                    
                    break // Use first available health score in the window
                }
            }
        }
        
        // Calculate basic statistics
        let factorActiveAvg = factorActiveHealth.isEmpty ? 0 : factorActiveHealth.reduce(0, +) / Double(factorActiveHealth.count)
        let factorInactiveAvg = factorInactiveHealth.isEmpty ? 0 : factorInactiveHealth.reduce(0, +) / Double(factorInactiveHealth.count)
        
        // Calculate correlation coefficient (simplified)
        let correlation: Double
        let impact: FactorAnalysisResult.ImpactType
        let difference = factorActiveAvg - factorInactiveAvg
        
        if factorActiveHealth.count < 2 || factorInactiveHealth.count < 2 {
            correlation = 0
            impact = .neutral
        } else {
            // Normalize the difference to a -1 to 1 scale
            correlation = min(max(difference / 25.0, -1.0), 1.0)
            
            if correlation > 0.15 {
                impact = .positive
            } else if correlation < -0.15 {
                impact = .negative
            } else {
                impact = .neutral
            }
        }
        
        // Calculate confidence based on sample size
        let totalSamples = factorActiveHealth.count + factorInactiveHealth.count
        let confidence = min(Double(totalSamples) / 10.0, 1.0) // Saturates at 10+ samples
        
        // Create description
        let description: String
        if factorActiveHealth.count < 2 || factorInactiveHealth.count < 2 {
            description = "Not enough data to determine correlation"
        } else if abs(difference) < 5 {
            description = "No significant effect detected"
        } else if difference > 0 {
            description = "Skin health is \(Int(round(abs(difference)))) points better when this factor is present"
        } else {
            description = "Skin health is \(Int(round(abs(difference)))) points worse when this factor is present"
        }
        
        return FactorAnalysisResult(
            factorName: factorName,
            correlation: correlation,
            confidence: confidence,
            dataPoints: totalSamples,
            avgHealthWithFactor: factorActiveAvg,
            avgHealthWithoutFactor: factorInactiveAvg,
            description: description,
            impactType: impact
        )
    }
    
    // Analyze a continuous factor across a time window
    private func analyzeContinuousFactorAcrossTimeWindow(
        factorName: String,
        timeWindow: AnalysisTimeWindow,
        healthByDate: [Date: Double],
        lifestyleEntries: [LifestyleEntry],
        factorExtractor: (LifestyleEntry) -> Double,
        threshold: Double,
        comparison: (Double, Double) -> Bool
    ) -> FactorAnalysisResult {
        let calendar = Calendar.current
        
        var factorActiveHealth: [Double] = []
        var factorInactiveHealth: [Double] = []
        
        for entry in lifestyleEntries {
            let factorValue = factorExtractor(entry)
            let factorActive = comparison(factorValue, threshold)
            let entryDayStart = calendar.startOfDay(for: entry.date)
            
            // Look for health scores in the given time window
            for dayOffset in timeWindow.dayRange {
                if let futureDay = calendar.date(byAdding: .day, value: dayOffset, to: entryDayStart),
                   let healthScore = healthByDate[futureDay] {
                    
                    if factorActive {
                        factorActiveHealth.append(healthScore)
                    } else {
                        factorInactiveHealth.append(healthScore)
                    }
                    
                    break // Use first available health score in the window
                }
            }
        }
        
        // Calculate basic statistics
        let factorActiveAvg = factorActiveHealth.isEmpty ? 0 : factorActiveHealth.reduce(0, +) / Double(factorActiveHealth.count)
        let factorInactiveAvg = factorInactiveHealth.isEmpty ? 0 : factorInactiveHealth.reduce(0, +) / Double(factorInactiveHealth.count)
        
        // Calculate correlation coefficient (simplified)
        let correlation: Double
        let impact: FactorAnalysisResult.ImpactType
        let difference = factorActiveAvg - factorInactiveAvg
        
        if factorActiveHealth.count < 2 || factorInactiveHealth.count < 2 {
            correlation = 0
            impact = .neutral
        } else {
            // Normalize the difference to a -1 to 1 scale
            correlation = min(max(difference / 25.0, -1.0), 1.0)
            
            if correlation > 0.15 {
                impact = .positive
            } else if correlation < -0.15 {
                impact = .negative
            } else {
                impact = .neutral
            }
        }
        
        // Calculate confidence based on sample size
        let totalSamples = factorActiveHealth.count + factorInactiveHealth.count
        let confidence = min(Double(totalSamples) / 10.0, 1.0) // Saturates at 10+ samples
        
        // Create description
        let description: String
        if factorActiveHealth.count < 2 || factorInactiveHealth.count < 2 {
            description = "Not enough data to determine correlation"
        } else if abs(difference) < 5 {
            description = "No significant effect detected"
        } else if difference > 0 {
            description = "Skin health is \(Int(round(abs(difference)))) points better with this factor"
        } else {
            description = "Skin health is \(Int(round(abs(difference)))) points worse with this factor"
        }
        
        return FactorAnalysisResult(
            factorName: factorName,
            correlation: correlation,
            confidence: confidence,
            dataPoints: totalSamples,
            avgHealthWithFactor: factorActiveAvg,
            avgHealthWithoutFactor: factorInactiveAvg,
            description: description,
            impactType: impact
        )
    }
    
    // Analyze a multi-factor combination across a time window
    private func analyzeMultiFactorCombination(
        factorName: String,
        timeWindow: AnalysisTimeWindow,
        healthByDate: [Date: Double],
        lifestyleEntries: [LifestyleEntry],
        factorCondition: (LifestyleEntry) -> Bool
    ) -> FactorAnalysisResult {
        let calendar = Calendar.current
        
        var factorActiveHealth: [Double] = []
        var factorInactiveHealth: [Double] = []
        
        for entry in lifestyleEntries {
            let combinationPresent = factorCondition(entry)
            let entryDayStart = calendar.startOfDay(for: entry.date)
            
            // Look for health scores in the given time window
            for dayOffset in timeWindow.dayRange {
                if let futureDay = calendar.date(byAdding: .day, value: dayOffset, to: entryDayStart),
                   let healthScore = healthByDate[futureDay] {
                    
                    if combinationPresent {
                        factorActiveHealth.append(healthScore)
                    } else {
                        factorInactiveHealth.append(healthScore)
                    }
                    
                    break // Use first available health score in the window
                }
            }
        }
        
        // Calculate basic statistics
        let factorActiveAvg = factorActiveHealth.isEmpty ? 0 : factorActiveHealth.reduce(0, +) / Double(factorActiveHealth.count)
        let factorInactiveAvg = factorInactiveHealth.isEmpty ? 0 : factorInactiveHealth.reduce(0, +) / Double(factorInactiveHealth.count)
        
        // Calculate correlation coefficient (simplified)
        let correlation: Double
        let impact: FactorAnalysisResult.ImpactType
        let difference = factorActiveAvg - factorInactiveAvg
        
        if factorActiveHealth.count < 2 || factorInactiveHealth.count < 2 {
            correlation = 0
            impact = .neutral
        } else {
            // Normalize the difference to a -1 to 1 scale
            correlation = min(max(difference / 25.0, -1.0), 1.0)
            
            if correlation > 0.15 {
                impact = .positive
            } else if correlation < -0.15 {
                impact = .negative
            } else {
                impact = .neutral
            }
        }
        
        // Calculate confidence based on sample size (higher weight for multi-factor)
        let totalSamples = factorActiveHealth.count + factorInactiveHealth.count
        let confidence = min(Double(totalSamples) / 8.0, 1.0) // Saturates at 8+ samples
        
        // Create description
        let description: String
        if factorActiveHealth.count < 2 || factorInactiveHealth.count < 2 {
            description = "Not enough data to determine correlation"
        } else if abs(difference) < 5 {
            description = "No significant effect detected for this combination"
        } else if difference > 0 {
            description = "Skin health is \(Int(round(abs(difference)))) points better with this combination"
        } else {
            description = "Skin health is \(Int(round(abs(difference)))) points worse with this combination"
        }
        
        return FactorAnalysisResult(
            factorName: factorName,
            correlation: correlation,
            confidence: confidence,
            dataPoints: totalSamples,
            avgHealthWithFactor: factorActiveAvg,
            avgHealthWithoutFactor: factorInactiveAvg,
            description: description,
            impactType: impact
        )
    }
}

// MARK: - Supporting Views

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

// Skin Health chart implementation (renamed from SeverityChart)
struct HistorySkinHealthChart: View {
    let skinEntries: [SkinEntry]
    
    var body: some View {
        if #available(iOS 16.0, *) {
            Chart {
                ForEach(skinEntries) { entry in
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Health", entry.severityScore)
                    )
                    .foregroundStyle(Color.green.gradient)
                    
                    PointMark(
                        x: .value("Date", entry.date),
                        y: .value("Health", entry.severityScore)
                    )
                    .foregroundStyle(Color.green)
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

// Updated HistoryCorrelationView
struct HistoryCorrelationView: View {
    let correlations: [HistoryCorrelationResult]
    @State private var showDetailedAnalysis = false
    @State private var selectedFactor: String? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            if correlations.isEmpty {
                Text("Not enough data to analyze correlations")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ForEach(correlations) { correlation in
                    Button(action: {
                        selectedFactor = correlation.factor
                        showDetailedAnalysis = true
                    }) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                // Icon based on whether this is positive or negative for skin health
                                Image(systemName: correlationTypeIcon(for: correlation))
                                    .foregroundColor(correlationTypeColor(for: correlation))
                                    .font(.system(size: 16, weight: .bold))
                                
                                Text(correlation.factor)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                // Correlation strength stars
                                HStack(spacing: 2) {
                                    ForEach(0..<5, id: \.self) { index in
                                        Circle()
                                            .fill(index < Int(correlation.correlationStrength * 5) ? correlationTypeColor(for: correlation) : Color.gray.opacity(0.3))
                                            .frame(width: 8, height: 8)
                                    }
                                }
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            
                            Text(correlation.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                            
                            if correlation.correlationStrength > 0 {
                                ProgressView(value: correlation.correlationStrength)
                                    .progressViewStyle(LinearProgressViewStyle(tint: correlationTypeColor(for: correlation)))
                            }
                        }
                        .padding()
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Add a note about data significance
                VStack(alignment: .leading, spacing: 4) {
                    Text("About This Analysis")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Text("Correlation scores are calculated based on your historical data. Stronger correlations suggest a possible relationship, but don't necessarily indicate causation.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
                .padding(.horizontal, 4)
            }
        }
        .sheet(isPresented: $showDetailedAnalysis) {
            if let factor = selectedFactor {
                FactorDetailView(factorName: factor, correlations: correlations)
            }
        }
    }
    
    private func correlationTypeIcon(for correlation: HistoryCorrelationResult) -> String {
        if correlation.description.contains("better") || correlation.description.contains("improved") {
            return "arrow.up.circle.fill"
        } else if correlation.description.contains("worse") || correlation.description.contains("reduced") {
            return "arrow.down.circle.fill"
        } else {
            return "equal.circle.fill"
        }
    }
    
    private func correlationTypeColor(for correlation: HistoryCorrelationResult) -> Color {
        if correlation.description.contains("better") || correlation.description.contains("improved") {
            return .green
        } else if correlation.description.contains("worse") || correlation.description.contains("reduced") {
            return .red
        } else {
            return .blue
        }
    }
}

// New view for detailed factor analysis
struct FactorDetailView: View {
    let factorName: String
    let correlations: [HistoryCorrelationResult]
    @Environment(\.presentationMode) var presentationMode
    
    var correlation: HistoryCorrelationResult? {
        correlations.first(where: { $0.factor == factorName })
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Factor Header
                    HStack {
                        Image(systemName: factorIcon(for: factorName))
                            .font(.system(size: 36))
                            .foregroundColor(factorColor(for: factorName))
                            .frame(width: 60, height: 60)
                            .background(factorColor(for: factorName).opacity(0.1))
                            .cornerRadius(30)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(factorName)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            if let correlation = correlation {
                                Text(correlation.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Impact on Skin Health
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Impact on Skin Health")
                            .font(.headline)
                        
                        if let correlation = correlation {
                            ImpactBarView(
                                strength: correlation.correlationStrength,
                                isPositive: correlation.description.contains("better") || correlation.description.contains("improved")
                            )
                        } else {
                            Text("No impact data available")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Recommendations for this factor
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recommendations")
                            .font(.headline)
                        
                        ForEach(recommendationsForFactor(factorName), id: \.self) { recommendation in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .frame(width: 20, height: 20)
                                
                                Text(recommendation)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Additional information
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About This Factor")
                            .font(.headline)
                        
                        Text(informationForFactor(factorName))
                            .font(.subheadline)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Next steps
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Next Steps")
                            .font(.headline)
                        
                        Text("Keep logging your daily activities and skin condition to improve the accuracy of these insights. The more data you provide, the more personalized your recommendations will become.")
                            .font(.subheadline)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Factor Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Done")
                    }
                }
            }
        }
    }
    
    private func factorIcon(for factor: String) -> String {
        switch factor {
        case "Dairy Consumption": return "cup.and.saucer.fill"
        case "Sugar Consumption": return "cube.fill"
        case "Alcohol Consumption": return "wineglass.fill"
        case "Fast Food": return "hamburger.fill"
        case "High Protein Diet": return "fork.knife"
        case "Low Sleep", "High Sleep": return "bed.double.fill"
        case "High Stress": return "brain.head.profile"
        case "Low Water Intake", "High Water Intake": return "drop.fill"
        case "Many Fruits & Veggies": return "leaf.fill"
        case "High Mood": return "face.smiling.fill"
        case "High Anxiety": return "waveform.path.ecg"
        case "Sunscreen Use": return "sun.max.fill"
        case "Makeup Use": return "paintbrush.fill"
        case "Face Wash Use": return "water.waves"
        case "Moisturizer Use": return "hand.raised.fill"
        case "Acne Treatment": return "cross.case.fill"
        case "Fresh Pillowcase": return "bed.double.fill"
        case "Travel": return "airplane"
        case "Climate Change": return "cloud.sun.fill"
        case "Outdoor Exposure", "High Sun Exposure": return "sun.max.fill"
        case "Stress + Dairy": return "brain.head.profile"
        case "Sugar + Low Sleep": return "moon.zzz.fill"
        default: return "questionmark.circle.fill"
        }
    }
    
    private func factorColor(for factor: String) -> Color {
        if let correlation = correlation {
            if correlation.description.contains("better") || correlation.description.contains("improved") {
                return .green
            } else if correlation.description.contains("worse") || correlation.description.contains("reduced") {
                return .red
            }
        }
        
        // Default colors by category
        if factor.contains("Sleep") {
            return .blue
        } else if factor.contains("Stress") || factor.contains("Anxiety") {
            return .purple
        } else if factor.contains("Dairy") || factor.contains("Sugar") || factor.contains("Protein") || factor.contains("Food") {
            return .orange
        } else if factor.contains("Water") {
            return .blue
        } else if factor.contains("Sun") || factor.contains("Outdoor") {
            return .yellow
        } else {
            return .gray
        }
    }
    
    private func recommendationsForFactor(_ factor: String) -> [String] {
        switch factor {
        case "Dairy Consumption":
            return [
                "Consider a two-week dairy elimination trial to see if your skin improves.",
                "If you consume dairy, opt for low-fat options which may have less impact on skin.",
                "Consider plant-based alternatives like almond, oat, or soy milk."
            ]
        case "Sugar Consumption":
            return [
                "Reduce intake of high-glycemic foods like candy, soda, and refined carbohydrates.",
                "Choose complex carbohydrates that don't cause blood sugar spikes.",
                "Read food labels to identify hidden sugars in processed foods."
            ]
        case "Low Sleep":
            return [
                "Aim for 7-8 hours of quality sleep per night.",
                "Establish a consistent sleep schedule, even on weekends.",
                "Create a relaxing bedtime routine and avoid screens 1 hour before sleep."
            ]
        case "High Stress":
            return [
                "Practice daily stress-reduction techniques like meditation or deep breathing.",
                "Build regular physical activity into your routine.",
                "Consider keeping a stress journal to identify and manage triggers."
            ]
        case "Low Water Intake":
            return [
                "Aim to drink at least 8 glasses of water daily.",
                "Set reminders or use a tracking app to ensure consistent hydration.",
                "Carry a reusable water bottle with you throughout the day."
            ]
        default:
            if factor.contains("Sunscreen") {
                return [
                    "Use a broad-spectrum SPF 30+ sunscreen daily, even on cloudy days.",
                    "Reapply sunscreen every 2 hours when outdoors.",
                    "Consider using mineral-based sunscreens if chemical ones irritate your skin."
                ]
            } else if factor.contains("Moisturizer") {
                return [
                    "Apply moisturizer to slightly damp skin after cleansing.",
                    "Choose non-comedogenic formulas that won't clog pores.",
                    "Consider using a lightweight gel moisturizer if you have oily skin."
                ]
            } else if factor.contains("Pillowcase") {
                return [
                    "Change your pillowcase at least once a week.",
                    "Consider using silk or copper-infused pillowcases.",
                    "Avoid fabric softeners that may irritate skin."
                ]
            } else {
                return [
                    "Track this factor consistently in your daily log.",
                    "Consider discussing with a dermatologist if this seems to be a significant trigger.",
                    "Try a two-week elimination test to confirm the correlation."
                ]
            }
        }
    }
    
    private func informationForFactor(_ factor: String) -> String {
        switch factor {
        case "Dairy Consumption":
            return "Dairy products contain hormones and growth factors that may influence skin health. Some studies suggest links between dairy consumption and acne, particularly with skim milk products."
        case "Sugar Consumption":
            return "High sugar intake can trigger insulin spikes, which may increase sebum production and inflammation. Reducing high-glycemic foods has been shown to improve acne in multiple studies."
        case "Low Sleep":
            return "Sleep deprivation increases stress hormones like cortisol, which can trigger inflammation and worsen skin conditions. Quality sleep is essential for skin repair and regeneration."
        case "High Stress":
            return "Stress increases cortisol levels, which can stimulate oil glands and worsen inflammatory skin conditions like acne. Chronic stress may also impair the skin barrier function."
        case "Low Water Intake":
            return "Proper hydration is crucial for maintaining skin barrier function and eliminating toxins. Dehydration can make skin appear dull and accentuate the appearance of fine lines and wrinkles."
        case "High Sun Exposure":
            return "UV radiation damages skin cells and accelerates aging. It can also trigger inflammatory responses and worsen hyperpigmentation in acne-prone skin."
        case "Fresh Pillowcase":
            return "Pillowcases can accumulate oils, bacteria, and dead skin cells. Regularly changing your pillowcase may help reduce exposure to these potential irritants."
        default:
            return "This factor has been identified as potentially relevant to your skin health based on your logged data. Continue tracking to improve the accuracy of this analysis."
        }
    }
}

// Impact Strength Visualization
struct ImpactBarView: View {
    let strength: Double
    let isPositive: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Impact description
            HStack {
                Text(impactDescription)
                    .font(.headline)
                    .foregroundColor(isPositive ? .green : .red)
                
                Spacer()
                
                Text("\(Int(strength * 100))%")
                    .font(.headline)
                    .foregroundColor(isPositive ? .green : .red)
            }
            
            // Impact bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: geometry.size.width, height: 24)
                        .cornerRadius(12)
                    
                    // Foreground
                    Rectangle()
                        .fill(isPositive ? Color.green : Color.red)
                        .frame(width: max(CGFloat(strength) * geometry.size.width, 24), height: 24)
                        .cornerRadius(12)
                }
            }
            .frame(height: 24)
            
            // Impact scale labels
            HStack {
                Text("Minimal")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text("Significant")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
    
    var impactDescription: String {
        if isPositive {
            return "Positive Impact"
        } else {
            return "Negative Impact"
        }
    }
}
