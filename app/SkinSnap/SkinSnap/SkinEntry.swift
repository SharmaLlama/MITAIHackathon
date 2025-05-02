//
//  SkinEntry.swift
//  SkinSnap
//
//  Created by Utkarsh sharma on 3/5/2025.
//


import Foundation
import SwiftData

// MARK: - Swift Data Models

@Model
class SkinEntry {
    var id: UUID
    var date: Date
    var severityScore: Double
    var condition: String
    var imageData: Data?
    @Relationship(deleteRule: .cascade) var regions: [RegionSeverity]?
    
    init(id: UUID = UUID(), 
         date: Date, 
         severityScore: Double, 
         condition: String, 
         imageData: Data? = nil,
         regions: [RegionSeverity]? = nil) {
        self.id = id
        self.date = date
        self.severityScore = severityScore
        self.condition = condition
        self.imageData = imageData
        self.regions = regions
    }
    
    // Helper to create a skin entry with associated regions
    static func create(date: Date, 
                      severityScore: Double, 
                      condition: String,
                      imageData: Data?,
                      regions: [FaceRegion]) -> SkinEntry {
        
        let regionEntities = regions.map { region in
            RegionSeverity(name: region.name, severity: region.severity)
        }
        
        return SkinEntry(
            date: date,
            severityScore: severityScore,
            condition: condition,
            imageData: imageData,
            regions: regionEntities
        )
    }
}

@Model
class RegionSeverity {
    var id: UUID
    var name: String
    var severity: Double
    
    init(id: UUID = UUID(), name: String, severity: Double) {
        self.id = id
        self.name = name
        self.severity = severity
    }
}

@Model
class LifestyleEntry {
    var id: UUID
    var date: Date
    var sleepHours: Double
    var stressLevel: Int
    var waterIntake: Int
    var dairyConsumed: Bool
    var sugarConsumed: Bool
    var alcoholConsumed: Bool
    var notes: String?
    
    init(id: UUID = UUID(), 
         date: Date, 
         sleepHours: Double, 
         stressLevel: Int, 
         waterIntake: Int, 
         dairyConsumed: Bool, 
         sugarConsumed: Bool, 
         alcoholConsumed: Bool, 
         notes: String? = nil) {
        self.id = id
        self.date = date
        self.sleepHours = sleepHours
        self.stressLevel = stressLevel
        self.waterIntake = waterIntake
        self.dairyConsumed = dairyConsumed
        self.sugarConsumed = sugarConsumed
        self.alcoholConsumed = alcoholConsumed
        self.notes = notes
    }
}

// MARK: - Helper extensions for model querying

extension SkinEntry {
    // Get entries within date range
    static func entriesInRange(modelContext: ModelContext, from startDate: Date, to endDate: Date) -> [SkinEntry] {
        let predicate = #Predicate<SkinEntry> { entry in
            entry.date >= startDate && entry.date <= endDate
        }
        
        let descriptor = FetchDescriptor<SkinEntry>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching skin entries: \(error.localizedDescription)")
            return []
        }
    }
}

extension LifestyleEntry {
    // Get lifestyle entry for specific date
    static func entryForDate(modelContext: ModelContext, date: Date) -> LifestyleEntry? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return nil
        }
        
        let predicate = #Predicate<LifestyleEntry> { entry in
            entry.date >= startOfDay && entry.date < endOfDay
        }
        
        var descriptor = FetchDescriptor<LifestyleEntry>(   // Change let to var here
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        descriptor.fetchLimit = 1
        
        do {
            let results = try modelContext.fetch(descriptor)
            return results.first
        } catch {
            print("Error fetching lifestyle entry: \(error.localizedDescription)")
            return nil
        }
    }

    
    // Get entries within date range
    static func entriesInRange(modelContext: ModelContext, from startDate: Date, to endDate: Date) -> [LifestyleEntry] {
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
}

// MARK: - Supporting Models for Analysis

// Models used for skin analysis (not stored in SwiftData)
struct SkinAnalysisResult {
    let date: Date
    let severityScore: Double  // 0-100 scale
    let condition: String      // Classification label
    let confidence: Float      // Model confidence
    let affectedAreas: [FaceRegion]
    
    // Generate heatmap data
    func heatmapData() -> HeatmapData {
        // In a real app, convert affected areas to a visual heatmap
        return HeatmapData(
            intensityMap: affectedAreas.map { ($0.name, $0.severity) },
            maxIntensity: affectedAreas.map { $0.severity }.max() ?? 0.0
        )
    }
    
    // Convert to SwiftData model for storage
    func toSkinEntry(imageData: Data?) -> SkinEntry {
        return SkinEntry.create(
            date: date,
            severityScore: severityScore,
            condition: condition,
            imageData: imageData,
            regions: affectedAreas
        )
    }
}

struct FaceRegion {
    let name: String
    let severity: Double  // 0.0 to 1.0
}

struct HeatmapData {
    let intensityMap: [(String, Double)]
    let maxIntensity: Double
}
