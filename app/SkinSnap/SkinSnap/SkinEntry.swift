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
    var lesionCount: Int // Added lesion count property
    var imageData: Data?
    @Relationship(deleteRule: .cascade) var regions: [RegionSeverity]?
    
    init(id: UUID = UUID(),
         date: Date,
         severityScore: Double,
         condition: String,
         lesionCount: Int = 0, // Added with default value
         imageData: Data? = nil,
         regions: [RegionSeverity]? = nil) {
        self.id = id
        self.date = date
        self.severityScore = severityScore
        self.condition = condition
        self.lesionCount = lesionCount
        self.imageData = imageData
        self.regions = regions
    }
    
    // Helper to create a skin entry with associated regions
    static func create(date: Date,
                      severityScore: Double,
                      condition: String,
                      lesionCount: Int, // Added lesion count parameter
                      imageData: Data?,
                      regions: [FaceRegion]) -> SkinEntry {
        
        let regionEntities = regions.map { region in
            RegionSeverity(name: region.name, severity: region.severity)
        }
        
        return SkinEntry(
            date: date,
            severityScore: severityScore,
            condition: condition,
            lesionCount: lesionCount, // Pass the lesion count
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
    
    // Existing fields
    var sleepHours: Double
    var stressLevel: Int
    var waterIntake: Int
    var dairyConsumed: Bool
    var sugarConsumed: Bool
    var alcoholConsumed: Bool
    
    // New diet fields
    var fastFoodConsumed: Bool
    var highProteinMeal: Bool
    var fruitsAndVeggiesServings: Int
    
    // New stress/mood fields
    var moodRating: Int // 1-5 scale
    var anxietyLevel: Int // 1-5 scale
    
    // New location/travel fields
    var traveledRecently: Bool
    var currentLocation: String?
    var climateChange: Bool
    
    // New product usage fields
    var usedSunscreen: Bool
    var usedMakeup: Bool
    var usedFaceWash: Bool
    var usedMoisturizer: Bool
    var usedAcneTreatment: Bool
    var changedPillowcase: Bool
    
    // New outdoor exposure
    var outdoorHours: Double
    var sunExposureLevel: Int // 1-5 scale
    
    var notes: String?
    
    init(id: UUID = UUID(),
         date: Date,
         sleepHours: Double,
         stressLevel: Int,
         waterIntake: Int,
         dairyConsumed: Bool,
         sugarConsumed: Bool,
         alcoholConsumed: Bool,
         fastFoodConsumed: Bool = false,
         highProteinMeal: Bool = false,
         fruitsAndVeggiesServings: Int = 0,
         moodRating: Int = 3,
         anxietyLevel: Int = 1,
         traveledRecently: Bool = false,
         currentLocation: String? = nil,
         climateChange: Bool = false,
         usedSunscreen: Bool = false,
         usedMakeup: Bool = false,
         usedFaceWash: Bool = false,
         usedMoisturizer: Bool = false,
         usedAcneTreatment: Bool = false,
         changedPillowcase: Bool = false,
         outdoorHours: Double = 0.0,
         sunExposureLevel: Int = 1,
         notes: String? = nil) {
        self.id = id
        self.date = date
        self.sleepHours = sleepHours
        self.stressLevel = stressLevel
        self.waterIntake = waterIntake
        self.dairyConsumed = dairyConsumed
        self.sugarConsumed = sugarConsumed
        self.alcoholConsumed = alcoholConsumed
        self.fastFoodConsumed = fastFoodConsumed
        self.highProteinMeal = highProteinMeal
        self.fruitsAndVeggiesServings = fruitsAndVeggiesServings
        self.moodRating = moodRating
        self.anxietyLevel = anxietyLevel
        self.traveledRecently = traveledRecently
        self.currentLocation = currentLocation
        self.climateChange = climateChange
        self.usedSunscreen = usedSunscreen
        self.usedMakeup = usedMakeup
        self.usedFaceWash = usedFaceWash
        self.usedMoisturizer = usedMoisturizer
        self.usedAcneTreatment = usedAcneTreatment
        self.changedPillowcase = changedPillowcase
        self.outdoorHours = outdoorHours
        self.sunExposureLevel = sunExposureLevel
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

struct SkinAnalysisResult {
    let date: Date
    let severityScore: Double
    let condition: String
    let confidence: Float
    let affectedAreas: [FaceRegion]
    let lesionCount: Int
    
    // Add the toSkinEntry method
    func toSkinEntry(imageData: Data?) -> SkinEntry {
        // Convert face regions to region severity entities
        let regionEntities = affectedAreas.map { area in
            RegionSeverity(name: area.name, severity: area.severity)
        }
        
        // Create and return a new SkinEntry
        return SkinEntry(
            date: date,
            severityScore: severityScore,
            condition: condition,
            lesionCount: lesionCount,
            imageData: imageData,
            regions: regionEntities
        )
    }
}

// Structure to represent a region of the face
struct FaceRegion {
    let name: String
    let severity: Double
}

struct HeatmapData {
    let intensityMap: [(String, Double)]
    let maxIntensity: Double
}

