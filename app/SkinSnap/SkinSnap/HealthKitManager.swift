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
