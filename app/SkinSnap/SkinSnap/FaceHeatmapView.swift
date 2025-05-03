////
////  FaceHeatmapView.swift
////  SkinSnap
////
////  Created by Utkarsh sharma on 3/5/2025.
////
//
//
//import SwiftUI
//
//struct FaceHeatmapView: View {
//    let skinEntries: [SkinEntry]
//    let timeRange: HistoryTimeRange
//    
//    @State private var currentTimeIndex: Int = 0
//    @State private var showingTimeSlider: Bool = false
//    
//    // Define the face regions
//    private let regions = ["Forehead", "Cheeks", "Chin", "Nose"]
//    
//    // Get entries grouped by time period
//    private var entriesByTimePeriod: [[SkinEntry]] {
//        guard !skinEntries.isEmpty else { return [] }
//        
//        let sortedEntries = skinEntries.sorted { $0.date < $1.date }
//        let calendar = Calendar.current
//        
//        switch timeRange {
//        case .week:
//            // Group by day
//            return groupEntriesByTimeUnit(entries: sortedEntries) { date in
//                calendar.startOfDay(for: date)
//            }
//        case .month:
//            // Group by 3-day periods
//            return groupEntriesByTimeUnit(entries: sortedEntries) { date in
//                let components = calendar.dateComponents([.year, .month, .day], from: date)
//                let day = components.day ?? 1
//                let period = (day - 1) / 3
//                var newComponents = DateComponents()
//                newComponents.year = components.year
//                newComponents.month = components.month
//                newComponents.day = period * 3 + 1
//                return calendar.date(from: newComponents) ?? date
//            }
//        case .threeMonths, .sixMonths:
//            // Group by week
//            return groupEntriesByTimeUnit(entries: sortedEntries) { date in
//                let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
//                return calendar.date(from: components) ?? date
//            }
//        case .year:
//            // Group by month
//            return groupEntriesByTimeUnit(entries: sortedEntries) { date in
//                let components = calendar.dateComponents([.year, .month], from: date)
//                return calendar.date(from: components) ?? date
//            }
//        }
//    }
//    
//    // Group entries by a time unit using the provided key generator
//    private func groupEntriesByTimeUnit(entries: [SkinEntry], keyForDate: (Date) -> Date) -> [[SkinEntry]] {
//        var groups: [Date: [SkinEntry]] = [:]
//        
//        for entry in entries {
//            let key = keyForDate(entry.date)
//            if groups[key] == nil {
//                groups[key] = []
//            }
//            groups[key]?.append(entry)
//        }
//        
//        // Sort by date and return values
//        return groups.sorted { $0.key < $1.key }.map { $0.value }
//    }
//    
//    // Get time period label
//    private var timePeriodLabel: String {
//        guard !entriesByTimePeriod.isEmpty, currentTimeIndex < entriesByTimePeriod.count else {
//            return "No data"
//        }
//        
//        let entries = entriesByTimePeriod[currentTimeIndex]
//        guard let firstDate = entries.first?.date, let lastDate = entries.last?.date else {
//            return "No data"
//        }
//        
//        let formatter = DateFormatter()
//        
//        switch timeRange {
//        case .week:
//            formatter.dateFormat = "MMM d"
//            return formatter.string(from: firstDate)
//        case .month:
//            formatter.dateFormat = "MMM d"
//            return "\(formatter.string(from: firstDate)) - \(formatter.string(from: lastDate))"
//        case .threeMonths, .sixMonths:
//            formatter.dateFormat = "MMM d"
//            return "Week of \(formatter.string(from: firstDate))"
//        case .year:
//            formatter.dateFormat = "MMMM yyyy"
//            return formatter.string(from: firstDate)
//        }
//    }
//    
//    // Calculate region severity for the current time period
//    private func severityForRegion(_ regionName: String) -> Double {
//        guard !entriesByTimePeriod.isEmpty, currentTimeIndex < entriesByTimePeriod.count else {
//            return 0
//        }
//        
//        let entries = entriesByTimePeriod[currentTimeIndex]
//        var severitySum: Double = 0
//        var count: Int = 0
//        
//        for entry in entries {
//            if let regions = entry.regions {
//                if let region = regions.first(where: { $0.name == regionName }) {
//                    severitySum += region.severity
//                    count += 1
//                }
//            }
//        }
//        
//        return count > 0 ? severitySum / Double(count) : 0
//    }
//    
//    // Map severity to color
//    private func colorForSeverity(_ severity: Double) -> Color {
//        // Convert severity (0-1) to heatmap color
//        let normalizedSeverity = min(max(severity, 0), 1)
//        
//        if normalizedSeverity < 0.2 {
//            return Color.green.opacity(0.1 + normalizedSeverity * 0.5)
//        } else if normalizedSeverity < 0.5 {
//            return Color.yellow.opacity(0.3 + normalizedSeverity * 0.5)
//        } else if normalizedSeverity < 0.8 {
//            return Color.orange.opacity(0.3 + normalizedSeverity * 0.5)
//        } else {
//            return Color.red.opacity(0.3 + normalizedSeverity * 0.5)
//        }
//    }
//    
//    var body: some View {
//        VStack(spacing: 16) {
//            if entriesByTimePeriod.isEmpty {
//                Text("No data available for this time range")
//                    .foregroundColor(.gray)
//                    .frame(height: 220)
//            } else {
//                // Time period navigation
//                HStack {
//                    Button(action: {
//                        withAnimation {
//                            currentTimeIndex = max(0, currentTimeIndex - 1)
//                        }
//                    }) {
//                        Image(systemName: "chevron.left")
//                            .foregroundColor(currentTimeIndex > 0 ? .blue : .gray)
//                    }
//                    .disabled(currentTimeIndex <= 0)
//                    
//                    Spacer()
//                    
//                    Text(timePeriodLabel)
//                        .font(.headline)
//                        .onTapGesture {
//                            withAnimation {
//                                showingTimeSlider.toggle()
//                            }
//                        }
//                    
//                    Spacer()
//                    
//                    Button(action: {
//                        withAnimation {
//                            currentTimeIndex = min(entriesByTimePeriod.count - 1, currentTimeIndex + 1)
//                        }
//                    }) {
//                        Image(systemName: "chevron.right")
//                            .foregroundColor(currentTimeIndex < entriesByTimePeriod.count - 1 ? .blue : .gray)
//                    }
//                    .disabled(currentTimeIndex >= entriesByTimePeriod.count - 1)
//                }
//                .padding(.horizontal)
//                
//                // Optional time slider
//                if showingTimeSlider && entriesByTimePeriod.count > 1 {
//                    VStack(spacing: 2) {
//                        Slider(value: Binding(
//                            get: { Double(self.currentTimeIndex) },
//                            set: { self.currentTimeIndex = Int($0) }
//                        ), in: 0...Double(entriesByTimePeriod.count - 1), step: 1)
//                        
//                        // Timeline labels
//                        HStack {
//                            Text(formatDate(entriesByTimePeriod.first?.first?.date))
//                                .font(.caption)
//                            
//                            Spacer()
//                            
//                            Text(formatDate(entriesByTimePeriod.last?.last?.date))
//                                .font(.caption)
//                        }
//                    }
//                    .padding(.horizontal)
//                }
//                
//                // Face heatmap visualization
//                ZStack {
//                    // Base face outline
//                    FaceOutlineView()
//                        .stroke(Color.gray, lineWidth: 2)
//                        .frame(width: 260, height: 300)
//                    
//                    // Forehead region
//                    ForeheadView()
//                        .fill(colorForSeverity(severityForRegion("Forehead")))
//                    
//                    // Left cheek region
//                    LeftCheekView()
//                        .fill(colorForSeverity(severityForRegion("Cheeks")))
//                    
//                    // Right cheek region
//                    RightCheekView()
//                        .fill(colorForSeverity(severityForRegion("Cheeks")))
//                    
//                    // Nose region
//                    NoseView()
//                        .fill(colorForSeverity(severityForRegion("Nose")))
//                    
//                    // Chin region
//                    ChinView()
//                        .fill(colorForSeverity(severityForRegion("Chin")))
//                }
//                .frame(height: 220)
//                
//                // Region legend
//                VStack(spacing: 12) {
//                    ForEach(regions, id: \.self) { region in
//                        let severity = severityForRegion(region)
//                        HStack {
//                            Circle()
//                                .fill(colorForSeverity(severity))
//                                .frame(width: 12, height: 12)
//                            
//                            Text(region)
//                                .font(.subheadline)
//                            
//                            Spacer()
//                            
//                            Text("\(Int(severity * 100))%")
//                                .font(.subheadline)
//                                .foregroundColor(colorForSeverity(severity))
//                        }
//                        .padding(.horizontal)
//                    }
//                }
//            }
//        }
//    }
//    
//    private func formatDate(_ date: Date?) -> String {
//        guard let date = date else { return "" }
//        let formatter = DateFormatter()
//        formatter.dateFormat = "MMM d"
//        return formatter.string(from: date)
//    }
//}
//
//// MARK: - Face Region Views
//
//// Base face outline
//struct FaceOutlineView: Shape {
//    func path(in rect: CGRect) -> Path {
//        let width = rect.width
//        let height = rect.height
//        
//        var path = Path()
//        
//        // Draw face outline (oval shape)
//        path.addEllipse(in: CGRect(x: width * 0.1, y: height * 0.05, width: width * 0.8, height: height * 0.9))
//        
//        return path
//    }
//}
//
//// Forehead region
//struct ForeheadView: Shape {
//    func path(in rect: CGRect) -> Path {
//        let width = rect.width
//        let height = rect.height
//        
//        var path = Path()
//        
//        // Draw forehead as upper part of the face
//        path.move(to: CGPoint(x: width * 0.1, y: height * 0.3))
//        path.addLine(to: CGPoint(x: width * 0.1, y: height * 0.05))
//        path.addCurve(
//            to: CGPoint(x: width * 0.9, y: height * 0.05),
//            control1: CGPoint(x: width * 0.3, y: height * -0.1),
//            control2: CGPoint(x: width * 0.7, y: height * -0.1)
//        )
//        path.addLine(to: CGPoint(x: width * 0.9, y: height * 0.3))
//        path.addCurve(
//            to: CGPoint(x: width * 0.1, y: height * 0.3),
//            control1: CGPoint(x: width * 0.7, y: height * 0.25),
//            control2: CGPoint(x: width * 0.3, y: height * 0.25)
//        )
//        path.closeSubpath()
//        
//        return path
//    }
//}
//
//// Left cheek region
//struct LeftCheekView: Shape {
//    func path(in rect: CGRect) -> Path {
//        let width = rect.width
//        let height = rect.height
//        
//        var path = Path()
//        
//        // Draw left cheek
//        path.move(to: CGPoint(x: width * 0.1, y: height * 0.3))
//        path.addLine(to: CGPoint(x: width * 0.1, y: height * 0.7))
//        path.addCurve(
//            to: CGPoint(x: width * 0.35, y: height * 0.65),
//            control1: CGPoint(x: width * 0.2, y: height * 0.7),
//            control2: CGPoint(x: width * 0.25, y: height * 0.65)
//        )
//        path.addCurve(
//            to: CGPoint(x: width * 0.35, y: height * 0.35),
//            control1: CGPoint(x: width * 0.35, y: height * 0.55),
//            control2: CGPoint(x: width * 0.35, y: height * 0.45)
//        )
//        path.addCurve(
//            to: CGPoint(x: width * 0.1, y: height * 0.3),
//            control1: CGPoint(x: width * 0.25, y: height * 0.35),
//            control2: CGPoint(x: width * 0.2, y: height * 0.3)
//        )
//        path.closeSubpath()
//        
//        return path
//    }
//}
//
//// Right cheek region
//struct RightCheekView: Shape {
//    func path(in rect: CGRect) -> Path {
//        let width = rect.width
//        let height = rect.height
//        
//        var path = Path()
//        
//        // Draw right cheek (mirror of left)
//        path.move(to: CGPoint(x: width * 0.9, y: height * 0.3))
//        path.addLine(to: CGPoint(x: width * 0.9, y: height * 0.7))
//        path.addCurve(
//            to: CGPoint(x: width * 0.65, y: height * 0.65),
//            control1: CGPoint(x: width * 0.8, y: height * 0.7),
//            control2: CGPoint(x: width * 0.75, y: height * 0.65)
//        )
//        path.addCurve(
//            to: CGPoint(x: width * 0.65, y: height * 0.35),
//            control1: CGPoint(x: width * 0.65, y: height * 0.55),
//            control2: CGPoint(x: width * 0.65, y: height * 0.45)
//        )
//        path.addCurve(
//            to: CGPoint(x: width * 0.9, y: height * 0.3),
//            control1: CGPoint(x: width * 0.75, y: height * 0.35),
//            control2: CGPoint(x: width * 0.8, y: height * 0.3)
//        )
//        path.closeSubpath()
//        
//        return path
//    }
//}
//
//// Nose region
//struct NoseView: Shape {
//    func path(in rect: CGRect) -> Path {
//        let width = rect.width
//        let height = rect.height
//        
//        var path = Path()
//        
//        // Draw nose in the center
//        path.move(to: CGPoint(x: width * 0.4, y: height * 0.35))
//        path.addLine(to: CGPoint(x: width * 0.4, y: height * 0.55))
//        path.addCurve(
//            to: CGPoint(x: width * 0.6, y: height * 0.55),
//            control1: CGPoint(x: width * 0.45, y: height * 0.6),
//            control2: CGPoint(x: width * 0.55, y: height * 0.6)
//        )
//        path.addLine(to: CGPoint(x: width * 0.6, y: height * 0.35))
//        path.addCurve(
//            to: CGPoint(x: width * 0.4, y: height * 0.35),
//            control1: CGPoint(x: width * 0.55, y: height * 0.35),
//            control2: CGPoint(x: width * 0.45, y: height * 0.35)
//        )
//        path.closeSubpath()
//        
//        return path
//    }
//}
//
//// Chin region
//struct ChinView: Shape {
//    func path(in rect: CGRect) -> Path {
//        let width = rect.width
//        let height = rect.height
//        
//        var path = Path()
//        
//        // Draw chin as bottom part of face
//        path.move(to: CGPoint(x: width * 0.35, y: height * 0.65))
//        path.addCurve(
//            to: CGPoint(x: width * 0.65, y: height * 0.65),
//            control1: CGPoint(x: width * 0.45, y: height * 0.65),
//            control2: CGPoint(x: width * 0.55, y: height * 0.65)
//        )
//        path.addCurve(
//            to: CGPoint(x: width * 0.7, y: height * 0.9),
//            control1: CGPoint(x: width * 0.68, y: height * 0.7),
//            control2: CGPoint(x: width * 0.7, y: height * 0.8)
//        )
//        path.addCurve(
//            to: CGPoint(x: width * 0.5, y: height * 0.95),
//            control1: CGPoint(x: width * 0.65, y: height * 0.95),
//            control2: CGPoint(x: width * 0.6, y: height * 0.95)
//        )
//        path.addCurve(
//            to: CGPoint(x: width * 0.3, y: height * 0.9),
//            control1: CGPoint(x: width * 0.4, y: height * 0.95),
//            control2: CGPoint(x: width * 0.35, y: height * 0.95)
//        )
//        path.addCurve(
//            to: CGPoint(x: width * 0.35, y: height * 0.65),
//            control1: CGPoint(x: width * 0.3, y: height * 0.8),
//            control2: CGPoint(x: width * 0.32, y: height * 0.7)
//        )
//        path.closeSubpath()
//        
//        return path
//    }
//}
