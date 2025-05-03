import Foundation
import SwiftUI

// Define TimeRange enum
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
    
    // Add method to get human-readable strength description
    var strengthDescription: String {
        switch correlationStrength {
        case 0..<0.2:
            return "Weak"
        case 0.2..<0.5:
            return "Moderate"
        case 0.5..<0.75:
            return "Strong"
        case 0.75...1.0:
            return "Very Strong"
        default:
            return "Unknown"
        }
    }
}
