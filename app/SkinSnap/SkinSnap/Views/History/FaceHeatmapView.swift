import SwiftUI

struct FaceHeatmapView: View {
    let skinEntries: [SkinEntry]
    let timeRange: HistoryTimeRange
    
    @State private var currentTimeIndex: Int = 0
    @State private var showingTimeSlider: Bool = false
    @State private var showingLegendExpanded: Bool = false
    
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
                
                // Expand button for legend
                if !showingLegendExpanded {
                    Button(action: {
                        withAnimation {
                            showingLegendExpanded = true
                        }
                    }) {
                        HStack {
                            Text("Show Region Details")
                            Image(systemName: "chevron.down")
                        }
                        .foregroundColor(.blue)
                        .font(.footnote)
                    }
                    .padding(.bottom, 2)
                }
                
                // Region legend - shows compact version by default, expanded view on tap
                if showingLegendExpanded {
                    VStack(spacing: 12) {
                        // Header with collapse button
                        HStack {
                            Text("Region Analysis")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation {
                                    showingLegendExpanded = false
                                }
                            }) {
                                Image(systemName: "chevron.up")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Region details
                        ForEach(regions, id: \.self) { region in
                            let severity = severityForRegion(region)
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Circle()
                                        .fill(colorForSeverity(severity))
                                        .frame(width: 12, height: 12)
                                    
                                    Text(region)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(severity * 100))%")
                                        .font(.subheadline)
                                        .foregroundColor(colorForSeverity(severity))
                                }
                                
                                // Add progress bar
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        // Background bar
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(height: 8)
                                            .cornerRadius(4)
                                        
                                        // Foreground bar
                                        Rectangle()
                                            .fill(colorForSeverity(severity))
                                            .frame(width: max(CGFloat(severity) * geometry.size.width, 4), height: 8)
                                            .cornerRadius(4)
                                    }
                                }
                                .frame(height: 8)
                                
                                // Severity text description
                                Text(severityDescription(for: severity))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                        }
                        
                        Divider()
                        
                        // Add advice based on the most affected region
                        if let mostAffectedRegion = getMostAffectedRegion() {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Advice")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                Text(adviceForRegion(mostAffectedRegion))
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .transition(.slide)
                } else {
                    // Compact legend view
                    HStack(spacing: 8) {
                        ForEach(regions, id: \.self) { region in
                            let severity = severityForRegion(region)
                            VStack {
                                Circle()
                                    .fill(colorForSeverity(severity))
                                    .frame(width: 8, height: 8)
                                
                                Text(region.prefix(1))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            if region != regions.last {
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                }
            }
        }
    }
    
    // Get most affected region
    private func getMostAffectedRegion() -> String? {
        var maxSeverity = 0.0
        var mostAffectedRegion: String? = nil
        
        for region in regions {
            let severity = severityForRegion(region)
            if severity > maxSeverity {
                maxSeverity = severity
                mostAffectedRegion = region
            }
        }
        
        return mostAffectedRegion
    }
    
    // Generate advice based on affected region
    private func adviceForRegion(_ region: String) -> String {
        switch region {
        case "Forehead":
            return "Your forehead shows the most activity. This area is often linked to stress and digestive issues. Try reducing stress, ensuring proper sleep, and avoiding foods that may trigger inflammation."
        case "Cheeks":
            return "Your cheeks show the most activity. This may be linked to respiratory issues, diet, or external factors like phone contact. Clean your phone regularly and consider if certain foods trigger breakouts."
        case "Chin":
            return "Your chin shows the most activity. This area often reflects hormonal fluctuations. Track your menstrual cycle (if applicable), ensure balanced diet, and consider consulting with a dermatologist about hormonal treatments."
        case "Nose":
            return "Your nose area shows the most activity. This area is typically linked to blood pressure and circulation issues. Ensure you're staying hydrated and consider introducing anti-inflammatory foods into your diet."
        default:
            return "Keep tracking your skin condition and lifestyle factors to identify patterns that may be triggering breakouts."
        }
    }
    
    // Descriptive text for severity levels
    private func severityDescription(for severity: Double) -> String {
        let severityLevel = Int(severity * 100)
        
        if severityLevel < 20 {
            return "Minimal activity - skin is in good condition"
        } else if severityLevel < 40 {
            return "Mild activity - minor concerns present"
        } else if severityLevel < 60 {
            return "Moderate activity - ongoing issues detected"
        } else if severityLevel < 80 {
            return "Significant activity - targeted treatment recommended"
        } else {
            return "Severe activity - consider consulting a dermatologist"
        }
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}
