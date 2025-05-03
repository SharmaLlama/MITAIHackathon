//
//  HistoryCorrelationView.swift
//  SkinSnap
//
//  Created by Utkarsh sharma on 3/5/2025.
//
import SwiftUI
import SwiftData
import Charts

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
                                
                                // Correlation strength as text instead of numbers
                                Text(correlationStrengthText(correlation.correlationStrength))
                                    .font(.subheadline)
                                    .foregroundColor(correlationTypeColor(for: correlation))
                                
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
                    
                    Text("Correlations suggest possible relationships between factors and your skin health, but don't necessarily indicate causation.")
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
    
    // Convert numerical correlation to descriptive text
    private func correlationStrengthText(_ strength: Double) -> String {
        switch strength {
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

// Improve ImpactBarView for the detail screen
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
                
                // Use descriptive text instead of percentage
                Text(strengthDescription)
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
    
    var strengthDescription: String {
        switch strength {
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
    
    var impactDescription: String {
        if isPositive {
            return "Positive Impact"
        } else {
            return "Negative Impact"
        }
    }
}
