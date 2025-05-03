import SwiftUI
import Charts

// Affected Areas Line Chart for iOS 16+
@available(iOS 16.0, *)
struct AffectedAreasLineChart: View {
    let affectedAreas: [FaceRegion]
    
    // Generate chart data points for consistency
    private var chartData: [AreaDataPoint] {
        let areas = ["Forehead", "Cheeks", "Chin", "Nose", "Eyes"]
        var dataPoints: [AreaDataPoint] = []
        
        // Add all possible face areas with 0 value
        for area in areas {
            dataPoints.append(AreaDataPoint(
                area: area,
                severity: 0,
                color: areaColor(area)
            ))
        }
        
        // Update with actual values from affectedAreas
        for area in affectedAreas {
            if let index = dataPoints.firstIndex(where: { $0.area == area.name }) {
                dataPoints[index].severity = area.severity * 100
            }
        }
        
        return dataPoints
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Affected Areas")
                .font(.headline)
                .padding(.bottom, 8)
            
            Chart {
                ForEach(chartData) { dataPoint in
                    LineMark(
                        x: .value("Area", dataPoint.area),
                        y: .value("Severity", dataPoint.severity)
                    )
                    .foregroundStyle(dataPoint.color)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    PointMark(
                        x: .value("Area", dataPoint.area),
                        y: .value("Severity", dataPoint.severity)
                    )
                    .foregroundStyle(dataPoint.color)
                    .symbolSize(CGSize(width: 10, height: 10))
                }
            }
            .frame(height: 200)
            .chartYScale(domain: 0...100)
            .chartLegend(.hidden)
            
            // Color legend
            VStack(alignment: .leading, spacing: 6) {
                ForEach(chartData.filter { $0.severity > 0 }) { dataPoint in
                    HStack {
                        Circle()
                            .fill(dataPoint.color)
                            .frame(width: 10, height: 10)
                        
                        Text(dataPoint.area)
                            .font(.caption)
                        
                        Spacer()
                        
                        Text("\(Int(dataPoint.severity))%")
                            .font(.caption)
                            .foregroundColor(dataPoint.color)
                    }
                }
            }
            .padding(.top, 10)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // Assign consistent colors to each face area
    private func areaColor(_ area: String) -> Color {
        switch area {
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

// Fallback chart for iOS 15 and earlier
struct AffectedAreasLegacyChart: View {
    let affectedAreas: [FaceRegion]
    
    // Generate chart data points for consistency
    private var chartData: [AreaDataPoint] {
        var dataPoints: [AreaDataPoint] = []
        
        // Add values from affectedAreas
        for area in affectedAreas {
            dataPoints.append(AreaDataPoint(
                area: area.name,
                severity: area.severity * 100,
                color: areaColor(area.name)
            ))
        }
        
        return dataPoints.sorted(by: { $0.area < $1.area })
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Affected Areas")
                .font(.headline)
                .padding(.bottom, 8)
            
            // Custom line graph
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height - 40
                let horizontalPadding: CGFloat = 20
                let availableWidth = width - (horizontalPadding * 2)
                
                ZStack {
                    // Background grid lines
                    VStack(spacing: height / 4) {
                        ForEach(0..<5) { i in
                            Divider()
                                .opacity(0.3)
                                .frame(width: availableWidth)
                        }
                    }
                    
                    // Y-axis labels
                    VStack(spacing: height / 4) {
                        ForEach([100, 75, 50, 25, 0], id: \.self) { value in
                            Text("\(value)")
                                .font(.system(size: 8))
                                .foregroundColor(.gray)
                                .frame(width: 20, alignment: .trailing)
                                .offset(x: -availableWidth/2 - 10)
                        }
                    }
                    
                    // Chart lines and points
                    if chartData.count > 0 {
                        // Draw lines
                        ForEach(0..<chartData.count-1, id: \.self) { i in
                            Path { path in
                                let startX = horizontalPadding + (availableWidth / CGFloat(chartData.count - 1)) * CGFloat(i)
                                let startY = height - (height * chartData[i].severity / 100)
                                let endX = horizontalPadding + (availableWidth / CGFloat(chartData.count - 1)) * CGFloat(i + 1)
                                let endY = height - (height * chartData[i+1].severity / 100)
                                
                                path.move(to: CGPoint(x: startX, y: startY))
                                path.addLine(to: CGPoint(x: endX, y: endY))
                            }
                            .stroke(chartData[i].color, lineWidth: 2)
                        }
                        
                        // Draw points
                        ForEach(0..<chartData.count, id: \.self) { i in
                            let pointX = horizontalPadding + (availableWidth / CGFloat(chartData.count - 1)) * CGFloat(i)
                            let pointY = height - (height * chartData[i].severity / 100)
                            
                            Circle()
                                .fill(chartData[i].color)
                                .frame(width: 8, height: 8)
                                .position(x: pointX, y: pointY)
                        }
                    }
                    
                    // X-axis labels
                    HStack(spacing: 0) {
                        ForEach(chartData) { dataPoint in
                            Text(dataPoint.area.prefix(3))
                                .font(.system(size: 8))
                                .foregroundColor(.gray)
                                .frame(width: availableWidth / CGFloat(chartData.count))
                        }
                    }
                    .offset(y: height + 10)
                }
            }
            .frame(height: 200)
            
            // Color legend
            VStack(alignment: .leading, spacing: 6) {
                ForEach(chartData) { dataPoint in
                    HStack {
                        Circle()
                            .fill(dataPoint.color)
                            .frame(width: 10, height: 10)
                        
                        Text(dataPoint.area)
                            .font(.caption)
                        
                        Spacer()
                        
                        Text("\(Int(dataPoint.severity))%")
                            .font(.caption)
                            .foregroundColor(dataPoint.color)
                    }
                }
            }
            .padding(.top, 10)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // Assign consistent colors to each face area
    private func areaColor(_ area: String) -> Color {
        switch area {
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

// Data structure for chart points
struct AreaDataPoint: Identifiable {
    let id = UUID()
    let area: String
    var severity: Double
    let color: Color
}