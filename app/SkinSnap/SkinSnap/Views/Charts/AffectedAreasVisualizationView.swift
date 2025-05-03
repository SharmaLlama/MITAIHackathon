//
//  AffectedAreasVisualizationView.swift
//  SkinSnap
//
//  Created by Utkarsh sharma on 3/5/2025.
//

import SwiftUI
import SwiftData
import Charts

// MARK: - Affected Areas Visualization View

struct AffectedAreasVisualizationView: View {
    let skinEntries: [SkinEntry]
    let timeRange: HistoryTimeRange
    @State private var selectedVisualization = 0
    
    var body: some View {
        VStack(spacing: 8) {
            // Visualization type selector - made more prominent
            HStack {
                Text("Visualization Mode:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Picker("Visualization", selection: $selectedVisualization) {
                    Text("Chart").tag(0)
                    Text("Face Map").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }
            .padding(.horizontal)
            
            // Show either the chart or face heatmap
            if selectedVisualization == 0 {
                HistoryAffectedAreasTimeSeriesChart(skinEntries: skinEntries)
            } else {
                // Add a ZStack to overlay a button on the face map
                ZStack(alignment: .topTrailing) {
                    FaceHeatmapView(skinEntries: skinEntries, timeRange: timeRange)
                    
                    // Easy toggle button to go back to chart mode
                    Button(action: {
                        selectedVisualization = 0
                    }) {
                        HStack {
                            Image(systemName: "chart.xyaxis.line")
                            Text("Switch to Chart")
                        }
                        .padding(8)
                        .background(Color.blue.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding(8)
                }
            }
        }
    }
}
