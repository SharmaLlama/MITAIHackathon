import Foundation
import HealthKit

class HealthKitManager: ObservableObject {
    private var healthStore: HKHealthStore?
    @Published var isAuthorized = false
    
    init() {
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
        }
    }
    
    func requestAuthorization() {
        guard let healthStore = healthStore else { return }
        
        // Define the types to read
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        
        // Request authorization
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.isAuthorized = true
                } else if let error = error {
                    print("HealthKit authorization failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Fetch sleep data for a given date
    func fetchSleepData(for date: Date, completion: @escaping (Double?) -> Void) {
        guard let healthStore = healthStore, isAuthorized else {
            completion(nil)
            return
        }
        
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        
        // Set up calendar for date range calculation
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // Define the predicate to filter by date range
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )
        
        // Create the query
        let query = HKSampleQuery(
            sampleType: sleepType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { _, samples, error in
            guard let samples = samples as? [HKCategorySample], error == nil else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            // Filter for "inBed" sleep samples
            let inBedSamples = samples.filter { $0.value == HKCategoryValueSleepAnalysis.inBed.rawValue }
            
            // Calculate total time in bed
            var totalSleepTime = 0.0
            for sample in inBedSamples {
                let sleepTime = sample.endDate.timeIntervalSince(sample.startDate) / 3600 // Convert to hours
                totalSleepTime += sleepTime
            }
            
            DispatchQueue.main.async {
                completion(totalSleepTime)
            }
        }
        
        healthStore.execute(query)
    }
    
    // Fetch step count for a given date
    func fetchStepCount(for date: Date, completion: @escaping (Int?) -> Void) {
        guard let healthStore = healthStore, isAuthorized else {
            completion(nil)
            return
        }
        
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        // Set up calendar for date range calculation
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // Define the predicate to filter by date range
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )
        
        // Create statistics query
        let query = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            guard let result = result, let sum = result.sumQuantity(), error == nil else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            let steps = Int(sum.doubleValue(for: HKUnit.count()))
            
            DispatchQueue.main.async {
                completion(steps)
            }
        }
        
        healthStore.execute(query)
    }
    
    // Fetch average heart rate for a given date
    func fetchAverageHeartRate(for date: Date, completion: @escaping (Double?) -> Void) {
        guard let healthStore = healthStore, isAuthorized else {
            completion(nil)
            return
        }
        
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        
        // Set up calendar for date range calculation
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // Define the predicate to filter by date range
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )
        
        // Create statistics query
        let query = HKStatisticsQuery(
            quantityType: heartRateType,
            quantitySamplePredicate: predicate,
            options: .discreteAverage
        ) { _, result, error in
            guard let result = result, let average = result.averageQuantity(), error == nil else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            let heartRate = average.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
            
            DispatchQueue.main.async {
                completion(heartRate)
            }
        }
        
        healthStore.execute(query)
    }
    
    // Get stress level estimate based on heart rate and other factors
    func getStressEstimate(for date: Date, completion: @escaping (Int?) -> Void) {
        
        fetchAverageHeartRate(for: date) { heartRate in
            guard let heartRate = heartRate else {
                completion(nil)
                return
            }
            
            // Very simplified stress level estimation based on heart rate
            var stressLevel: Int
            
            switch heartRate {
            case 0..<65:
                stressLevel = 1  // Very low
            case 65..<75:
                stressLevel = 2  // Low
            case 75..<85:
                stressLevel = 3  // Medium
            case 85..<95:
                stressLevel = 4  // High
            default:
                stressLevel = 5  // Very high
            }
            
            completion(stressLevel)
        }
    }
    
    // Comprehensive health data fetch for correlation analysis
    func fetchHealthDataForCorrelation(startDate: Date, endDate: Date, completion: @escaping ([Date: HealthDayData]) -> Void) {
        guard let healthStore = healthStore, isAuthorized else {
            completion([:])
            return
        }
        
        let calendar = Calendar.current
        let dispatchGroup = DispatchGroup()
        
        var currentDate = startDate
        var results: [Date: HealthDayData] = [:]
        
        while currentDate <= endDate {
            let dateKey = calendar.startOfDay(for: currentDate)
            results[dateKey] = HealthDayData(date: dateKey)
            
            // Fetch sleep data
            dispatchGroup.enter()
            fetchSleepData(for: currentDate) { sleepHours in
                if let sleepHours = sleepHours {
                    results[dateKey]?.sleepHours = sleepHours
                }
                dispatchGroup.leave()
            }
            
            // Fetch step count
            dispatchGroup.enter()
            fetchStepCount(for: currentDate) { steps in
                if let steps = steps {
                    results[dateKey]?.stepCount = steps
                }
                dispatchGroup.leave()
            }
            
            // Fetch heart rate
            dispatchGroup.enter()
            fetchAverageHeartRate(for: currentDate) { heartRate in
                if let heartRate = heartRate {
                    results[dateKey]?.averageHeartRate = heartRate
                }
                dispatchGroup.leave()
            }
            
            // Move to next day
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(results)
        }
    }
}

// Health data structure for daily values
struct HealthDayData {
    let date: Date
    var sleepHours: Double?
    var stepCount: Int?
    var averageHeartRate: Double?
    var estimatedStressLevel: Int?
    
    // Add computed properties to evaluate health factors
    var isSleepSufficient: Bool? {
        guard let sleepHours = sleepHours else { return nil }
        return sleepHours >= 7.0
    }
    
    var isActive: Bool? {
        guard let stepCount = stepCount else { return nil }
        return stepCount >= 7500
    }
    
    var isStressed: Bool? {
        guard let estimatedStressLevel = estimatedStressLevel else { return nil }
        return estimatedStressLevel >= 4
    }
}

// Extension to add new fitness tracking methods
extension HealthKitManager {
    
    // Request authorization for additional fitness data types
    func requestExtendedAuthorization() {
        guard let healthStore = healthStore else { return }
        
        // Add fitness activity and nutrition types to read
        let typesToRead: Set<HKObjectType> = [
            // Existing types
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            
            // Additional fitness types
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!,
            HKObjectType.quantityType(forIdentifier: .appleStandTime)!,
            HKObjectType.workoutType(),
            
            // Nutrition types
            HKObjectType.quantityType(forIdentifier: .dietaryWater)!,
            HKObjectType.quantityType(forIdentifier: .dietarySugar)!,
            HKObjectType.quantityType(forIdentifier: .dietaryFatTotal)!,
            
            // UV exposure
            HKObjectType.quantityType(forIdentifier: .uvExposure)!,
            
            // Mindfulness
            HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        ]
        
        // Request authorization
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.isAuthorized = true
                } else if let error = error {
                    print("HealthKit extended authorization failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Fetch exercise minutes for a given date
    func fetchExerciseMinutes(for date: Date, completion: @escaping (Int?) -> Void) {
        guard let healthStore = healthStore, isAuthorized else {
            completion(nil)
            return
        }
        
        let exerciseType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!
        
        // Set up calendar for date range calculation
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // Define the predicate to filter by date range
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )
        
        // Create statistics query
        let query = HKStatisticsQuery(
            quantityType: exerciseType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            guard let result = result, let sum = result.sumQuantity(), error == nil else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            let minutes = Int(sum.doubleValue(for: HKUnit.minute()))
            
            DispatchQueue.main.async {
                completion(minutes)
            }
        }
        
        healthStore.execute(query)
    }
    
    // Fetch distance walked or run for a given date
    func fetchDistance(for date: Date, completion: @escaping (Double?) -> Void) {
        guard let healthStore = healthStore, isAuthorized else {
            completion(nil)
            return
        }
        
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        
        // Set up calendar for date range calculation
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // Define the predicate to filter by date range
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )
        
        // Create statistics query
        let query = HKStatisticsQuery(
            quantityType: distanceType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            guard let result = result, let sum = result.sumQuantity(), error == nil else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            let kilometers = sum.doubleValue(for: HKUnit.meterUnit(with: .kilo))
            
            DispatchQueue.main.async {
                completion(kilometers)
            }
        }
        
        healthStore.execute(query)
    }
    
    // Fetch active calories burned for a given date
    func fetchActiveCalories(for date: Date, completion: @escaping (Int?) -> Void) {
        guard let healthStore = healthStore, isAuthorized else {
            completion(nil)
            return
        }
        
        let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        
        // Set up calendar for date range calculation
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // Define the predicate to filter by date range
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )
        
        // Create statistics query
        let query = HKStatisticsQuery(
            quantityType: caloriesType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            guard let result = result, let sum = result.sumQuantity(), error == nil else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            let calories = Int(sum.doubleValue(for: HKUnit.kilocalorie()))
            
            DispatchQueue.main.async {
                completion(calories)
            }
        }
        
        healthStore.execute(query)
    }
    
    // Fetch UV exposure for a given date
    func fetchUVExposure(for date: Date, completion: @escaping (Double?) -> Void) {
        guard let healthStore = healthStore, isAuthorized else {
            completion(nil)
            return
        }
        
        let uvType = HKQuantityType.quantityType(forIdentifier: .uvExposure)!
        
        // Set up calendar for date range calculation
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // Define the predicate to filter by date range
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )
        
        // Create statistics query
        let query = HKStatisticsQuery(
            quantityType: uvType,
            quantitySamplePredicate: predicate,
            options: .discreteAverage
        ) { _, result, error in
            guard let result = result, let average = result.averageQuantity(), error == nil else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            let uvIndex = average.doubleValue(for: HKUnit.count())
            
            DispatchQueue.main.async {
                completion(uvIndex)
            }
        }
        
        healthStore.execute(query)
    }
    
    // Fetch workout data for a given date range
    func fetchWorkouts(from startDate: Date, to endDate: Date, completion: @escaping ([HKWorkout]) -> Void) {
        guard let healthStore = healthStore, isAuthorized else {
            completion([])
            return
        }
        
        // Define the predicate to filter by date range
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
        
        // Create the query
        let query = HKSampleQuery(
            sampleType: HKObjectType.workoutType(),
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
        ) { _, samples, error in
            guard let workouts = samples as? [HKWorkout], error == nil else {
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }
            
            DispatchQueue.main.async {
                completion(workouts)
            }
        }
        
        healthStore.execute(query)
    }
    
    // Fetch all fitness data for a date range
    func fetchFitnessData(from startDate: Date, to endDate: Date, completion: @escaping ([Date: FitnessDayData]) -> Void) {
        guard let healthStore = healthStore, isAuthorized else {
            completion([:])
            return
        }
        
        let calendar = Calendar.current
        let dispatchGroup = DispatchGroup()
        
        var currentDate = startDate
        var results: [Date: FitnessDayData] = [:]
        
        while currentDate <= endDate {
            let dateKey = calendar.startOfDay(for: currentDate)
            results[dateKey] = FitnessDayData(date: dateKey)
            
            // Fetch step count
            dispatchGroup.enter()
            fetchStepCount(for: currentDate) { steps in
                if let steps = steps {
                    results[dateKey]?.stepCount = steps
                }
                dispatchGroup.leave()
            }
            
            // Fetch exercise minutes
            dispatchGroup.enter()
            fetchExerciseMinutes(for: currentDate) { minutes in
                if let minutes = minutes {
                    results[dateKey]?.exerciseMinutes = minutes
                }
                dispatchGroup.leave()
            }
            
            // Fetch distance
            dispatchGroup.enter()
            fetchDistance(for: currentDate) { distance in
                if let distance = distance {
                    results[dateKey]?.distanceKm = distance
                }
                dispatchGroup.leave()
            }
            
            // Fetch calories
            dispatchGroup.enter()
            fetchActiveCalories(for: currentDate) { calories in
                if let calories = calories {
                    results[dateKey]?.activeCalories = calories
                }
                dispatchGroup.leave()
            }
            
            // Fetch heart rate
            dispatchGroup.enter()
            fetchAverageHeartRate(for: currentDate) { heartRate in
                if let heartRate = heartRate {
                    results[dateKey]?.averageHeartRate = heartRate
                }
                dispatchGroup.leave()
            }
            
            // Fetch sleep
            dispatchGroup.enter()
            fetchSleepData(for: currentDate) { sleepHours in
                if let sleepHours = sleepHours {
                    results[dateKey]?.sleepHours = sleepHours
                }
                dispatchGroup.leave()
            }
            
            // Fetch UV exposure
            dispatchGroup.enter()
            fetchUVExposure(for: currentDate) { uvIndex in
                if let uvIndex = uvIndex {
                    results[dateKey]?.uvExposure = uvIndex
                }
                dispatchGroup.leave()
            }
            
            // Move to next day
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(results)
        }
    }
}

// Fitness data structure for daily values
struct FitnessDayData {
    let date: Date
    var stepCount: Int?
    var exerciseMinutes: Int?
    var distanceKm: Double?
    var activeCalories: Int?
    var sleepHours: Double?
    var averageHeartRate: Double?
    var uvExposure: Double?
    
    // Add computed properties to evaluate fitness levels
    var isActive: Bool? {
        guard let stepCount = stepCount else { return nil }
        return stepCount >= 7500
    }
    
    var isFitGoalMet: Bool? {
        guard let exerciseMinutes = exerciseMinutes else { return nil }
        return exerciseMinutes >= 30
    }
    
    var exerciseIntensity: String? {
        guard let heartRate = averageHeartRate else { return nil }
        
        if heartRate < 70 {
            return "Low"
        } else if heartRate < 90 {
            return "Moderate"
        } else {
            return "High"
        }
    }
    
    var sunExposureLevel: String? {
        guard let uvExposure = uvExposure else { return nil }
        
        if uvExposure < 3 {
            return "Low"
        } else if uvExposure < 6 {
            return "Moderate"
        } else if uvExposure < 8 {
            return "High"
        } else {
            return "Very High"
        }
    }
}
