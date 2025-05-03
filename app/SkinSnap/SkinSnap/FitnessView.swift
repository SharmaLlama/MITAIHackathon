//import SwiftUI
//import Charts
//import HealthKit
//
//struct FitnessView: View {
//    @EnvironmentObject private var healthKitManager: HealthKitManager
//    @State private var fitnessData: [Date: FitnessDayData] = [:]
//    @State private var selectedTimeRange: TimeRange = .week
//    @State private var isLoading = true
//    @State private var selectedWorkoutType: HKWorkoutActivityType? = nil
//    @State private var workouts: [HKWorkout] = []
//    
//    var dateRange: (start: Date, end: Date) {
//        let calendar = Calendar.current
//        let endDate = Date()
//        
//        switch selectedTimeRange {
//        case .week:
//            let startDate = calendar.date(byAdding: .day, value: -7, to: endDate)!
//            return (startDate, endDate)
//        case .month:
//            let startDate = calendar.date(byAdding: .month, value: -1, to: endDate)!
//            return (startDate, endDate)
//        case .threeMonths:
//            let startDate = calendar.date(byAdding: .month, value: -3, to: endDate)!
//            return (startDate, endDate)
//        case .sixMonths:
//            let startDate = calendar.date(byAdding: .month, value: -6, to: endDate)!
//            return (startDate, endDate)
//        case .year:
//            let startDate = calendar.date(byAdding: .year, value: -1, to: endDate)!
//            return (startDate, endDate)
//        }
//    }
//    
//    var body: some View {
//        NavigationStack {
//            ScrollView {
//                VStack(alignment: .leading, spacing: 20) {
//                    // Time range picker
//                    Picker("Time Range", selection: $selectedTimeRange) {
//                        Text("Week").tag(TimeRange.week)
//                        Text("Month").tag(TimeRange.month)
//                        Text("3 Months").tag(TimeRange.threeMonths)
//                        Text("6 Months").tag(TimeRange.sixMonths)
//                        Text("Year").tag(TimeRange.year)
//                    }
//                    .pickerStyle(SegmentedPickerStyle())
//                    .padding(.horizontal)
//                    .onChange(of: selectedTimeRange) { _, _ in
//                        loadFitnessData()
//                    }
//                    
//                    if isLoading {
//                        HStack {
//                            Spacer()
//                            ProgressView("Loading fitness data...")
//                            Spacer()
//                        }
//                        .padding()
//                    } else if fitnessData.isEmpty {
//                        HStack {
//                            Spacer()
//                            VStack(spacing: 12) {
//                                Image(systemName: "figure.run")
//                                    .font(.largeTitle)
//                                    .foregroundColor(.gray)
//                                Text("No fitness data for this period")
//                                    .font(.headline)
//                                Text("Connect to Apple Health to see your trends")
//                                    .font(.subheadline)
//                                    .foregroundColor(.gray)
//                                
//                                Button(action: {
//                                    healthKitManager.requestExtendedAuthorization()
//                                }) {
//                                    Text("Connect to Health")
//                                        .padding(.horizontal, 20)
//                                        .padding(.vertical, 10)
//                                        .background(Color.blue)
//                                        .foregroundColor(.white)
//                                        .cornerRadius(8)
//                                }
//                                .padding(.top, 10)
//                            }
//                            Spacer()
//                        }
//                        .padding()
//                    } else {
//                        // Daily Activity Summary
//                        SummaryCardView(fitnessData: fitnessData)
//                        
//                        // Steps Chart
//                        FitnessChartSection(title: "Steps") {
//                            StepsChartView(fitnessData: fitnessData)
//                        }
//                        
//                        // Exercise Minutes Chart
//                        FitnessChartSection(title: "Exercise Minutes") {
//                            ExerciseChartView(fitnessData: fitnessData)
//                        }
//                        
//                        // Heart Rate Chart
//                        FitnessChartSection(title: "Heart Rate") {
//                            HeartRateChartView(fitnessData: fitnessData)
//                        }
//                        
//                        // Sleep Chart
//                        FitnessChartSection(title: "Sleep Hours") {
//                            SleepChartView(fitnessData: fitnessData)
//                        }
//                        
//                        // Workout Summary
//                        if !workouts.isEmpty {
//                            WorkoutSummaryView(workouts: workouts)
//                        }
//                    }
//                }
//                .padding(.vertical)
//            }
//            .navigationTitle("Fitness Data")
//            .onAppear {
//                if healthKitManager.isAuthorized {
//                    loadFitnessData()
//                } else {
//                    isLoading = false
//                }
//            }
//        }
//    }
//    
//    private func loadFitnessData() {
//        isLoading = true
//        let (startDate, endDate) = dateRange
//        
//        // Load fitness data
//        healthKitManager.fetchFitnessData(from: startDate, to: endDate) { fitnessData in
//            self.fitnessData = fitnessData
//            
//            // Load workouts
//            healthKitManager.fetchWorkouts(from: startDate, to: endDate) { workouts in
//                self.workouts = workouts
//                self.isLoading = false
//            }
//        }
//    }
//}
//
//// MARK: - Supporting Views
//
//struct SummaryCardView: View {
//    let fitnessData: [Date: FitnessDayData]
//    
//    var averageSteps: Int {
//        let sum = fitnessData.compactMap { $0.value.stepCount }.reduce(0, +)
//        return fitnessData.isEmpty ? 0 : sum / fitnessData.count
//    }
//    
//    var averageExerciseMinutes: Int {
//        let sum = fitnessData.compactMap { $0.value.exerciseMinutes }.reduce(0, +)
//        return fitnessData.isEmpty ? 0 : sum / fitnessData.count
//    }
//    
//    var averageSleep: Double {
//        let sum = fitnessData.compactMap { $0.value.sleepHours }.reduce(0, +)
//        return fitnessData.isEmpty ? 0 : sum / Double(fitnessData.count)
//    }
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            Text("Daily Averages")
//                .font(.headline)
//                .padding(.horizontal)
//            
//            HStack(spacing: 0) {
//                // Steps
//                VStack(spacing: 8) {
//                    Image(systemName: "figure.walk")
//                        .font(.system(size: 24))
//                        .foregroundColor(.green)
//                    
//                    Text("\(averageSteps)")
//                        .font(.system(size: 20, weight: .bold))
//                    
//                    Text("Steps")
//                        .font(.caption)
//                        .foregroundColor(.gray)
//                }
//                .frame(maxWidth: .infinity)
//                
//                // Exercise
//                VStack(spacing: 8) {
//                    Image(systemName: "heart.fill")
//                        .font(.system(size: 24))
//                        .foregroundColor(.red)
//                    
//                    Text("\(averageExerciseMinutes)")
//                        .font(.system(size: 20, weight: .bold))
//                    
//                    Text("Exercise Min")
//                        .font(.caption)
//                        .foregroundColor(.gray)
//                }
//                .frame(maxWidth: .infinity)
//                
//                // Sleep
//                VStack(spacing: 8) {
//                    Image(systemName: "bed.double.fill")
//                        .font(.system(size: 24))
//                        .foregroundColor(.blue)
//                    
//                    Text("\(averageSleep, specifier: "%.1f")")
//                        .font(.system(size: 20, weight: .bold))
//                    
//                    Text("Sleep Hours")
//                        .font(.caption)
//                        .foregroundColor(.gray)
//                }
//                .frame(maxWidth: .infinity)
//            }
//            .padding(.horizontal)
//        }
//        .padding(.vertical, 16)
//        .background(Color(UIColor.secondarySystemBackground))
//        .cornerRadius(12)
//        .padding(.horizontal)
//    }
//}
//
//struct StepsChartView: View {
//    let fitnessData: [Date: FitnessDayData]
//    
//    // Convert dictionary to sorted array for charting
//    var chartData: [DataPoint] {
//        fitnessData.compactMap { date, data in
//            if let steps = data.stepCount {
//                return DataPoint(date: date, value: Double(steps))
//            }
//            return nil
//        }.sorted { $0.date < $1.date }
//    }
//    
//    var body: some View {
//        if chartData.isEmpty {
//            Text("No step data available")
//                .foregroundColor(.gray)
//                .frame(maxWidth: .infinity, alignment: .center)
//                .padding()
//        } else if #available(iOS 16.0, *) {
//            Chart {
//                ForEach(chartData) { dataPoint in
//                    BarMark(
//                        x: .value("Date", dataPoint.date, unit: .day),
//                        y: .value("Steps", dataPoint.value)
//                    )
//                    .foregroundStyle(Color.green.gradient)
//                }
//                
//                RuleMark(y: .value("Goal", 10000))
//                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
//                    .foregroundStyle(.gray)
//                    .annotation(position: .trailing) {
//                        Text("Goal")
//                            .font(.caption)
//                            .foregroundColor(.gray)
//                    }
//            }
//            .chartYAxis {
//                AxisMarks(position: .leading)
//            }
//        } else {
//            // Fallback for iOS 15
//            HStack(alignment: .bottom, spacing: 8) {
//                ForEach(chartData) { dataPoint in
//                    VStack {
//                        Spacer()
//                        
//                        RoundedRectangle(cornerRadius: 4)
//                            .fill(Color.green)
//                            .frame(width: 20, height: CGFloat(min(dataPoint.value / 200, 200)))
//                        
//                        Text(dateFormatter.string(from: dataPoint.date))
//                            .font(.caption2)
//                            .rotationEffect(.degrees(-45))
//                    }
//                }
//            }
//            .frame(height: 220)
//            .padding(.horizontal)
//        }
//    }
//    
//    private var dateFormatter: DateFormatter {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "MM/dd"
//        return formatter
//    }
//}
//
//struct ExerciseChartView: View {
//    let fitnessData: [Date: FitnessDayData]
//    
//    // Convert dictionary to sorted array for charting
//    var chartData: [DataPoint] {
//        fitnessData.compactMap { date, data in
//            if let exercise = data.exerciseMinutes {
//                return DataPoint(date: date, value: Double(exercise))
//            }
//            return nil
//        }.sorted { $0.date < $1.date }
//    }
//    
//    var body: some View {
//        if chartData.isEmpty {
//            Text("No exercise data available")
//                .foregroundColor(.gray)
//                .frame(maxWidth: .infinity, alignment: .center)
//                .padding()
//        } else if #available(iOS 16.0, *) {
//            Chart {
//                ForEach(chartData) { dataPoint in
//                    BarMark(
//                        x: .value("Date", dataPoint.date, unit: .day),
//                        y: .value("Minutes", dataPoint.value)
//                    )
//                    .foregroundStyle(Color.red.gradient)
//                }
//                
//                RuleMark(y: .value("Goal", 30))
//                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
//                    .foregroundStyle(.gray)
//                    .annotation(position: .trailing) {
//                        Text("Goal")
//                            .font(.caption)
//                            .foregroundColor(.gray)
//                    }
//            }
//            .chartYAxis {
//                AxisMarks(position: .leading)
//            }
//        } else {
//            // Fallback for iOS 15
//            HStack(alignment: .bottom, spacing: 8) {
//                ForEach(chartData) { dataPoint in
//                    VStack {
//                        Spacer()
//                        
//                        RoundedRectangle(cornerRadius: 4)
//                            .fill(Color.red)
//                            .frame(width: 20, height: CGFloat(min(dataPoint.value * 3, 200)))
//                        
//                        Text(dateFormatter.string(from: dataPoint.date))
//                            .font(.caption2)
//                            .rotationEffect(.degrees(-45))
//                    }
//                }
//            }
//            .frame(height: 220)
//            .padding(.horizontal)
//        }
//    }
//    
//    private var dateFormatter: DateFormatter {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "MM/dd"
//        return formatter
//    }
//}
//
//struct HeartRateChartView: View {
//    let fitnessData: [Date: FitnessDayData]
//    
//    // Convert dictionary to sorted array for charting
//    var chartData: [DataPoint] {
//        fitnessData.compactMap { date, data in
//            if let heartRate = data.averageHeartRate {
//                return DataPoint(date: date, value: heartRate)
//            }
//            return nil
//        }.sorted { $0.date < $1.date }
//    }
//    
//    var body: some View {
//        if chartData.isEmpty {
//            Text("No heart rate data available")
//                .foregroundColor(.gray)
//                .frame(maxWidth: .infinity, alignment: .center)
//                .padding()
//        } else if #available(iOS 16.0, *) {
//            Chart {
//                ForEach(chartData) { dataPoint in
//                    LineMark(
//                        x: .value("Date", dataPoint.date, unit: .day),
//                        y: .value("BPM", dataPoint.value)
//                    )
//                    .foregroundStyle(Color.pink)
//                    
//                    PointMark(
//                        x: .value("Date", dataPoint.date, unit: .day),
//                        y: .value("BPM", dataPoint.value)
//                    )
//                    .foregroundStyle(Color.pink)
//                }
//            }
//            .chartYAxis {
//                AxisMarks(position: .leading)
//            }
//        } else {
//            // Fallback for iOS 15
//            HStack(alignment: .bottom, spacing: 8) {
//                ForEach(chartData) { dataPoint in
//                    VStack {
//                        Spacer()
//                        
//                        Circle()
//                            .fill(Color.pink)
//                            .frame(width: 8, height: 8)
//                            .offset(y: -CGFloat(dataPoint.value))
//                        
//                        Text(dateFormatter.string(from: dataPoint.date))
//                            .font(.caption2)
//                            .rotationEffect(.degrees(-45))
//                    }
//                    .frame(height: 220)
//                }
//            }
//            .padding(.horizontal)
//        }
//    }
//    
//    private var dateFormatter: DateFormatter {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "MM/dd"
//        return formatter
//    }
//}
//
//struct SleepChartView: View {
//    let fitnessData: [Date: FitnessDayData]
//    
//    // Convert dictionary to sorted array for charting
//    var chartData: [DataPoint] {
//        fitnessData.compactMap { date, data in
//            if let sleep = data.sleepHours {
//                return DataPoint(date: date, value: sleep)
//            }
//            return nil
//        }.sorted { $0.date < $1.date }
//    }
//    
//    var body: some View {
//        if chartData.isEmpty {
//            Text("No sleep data available")
//                .foregroundColor(.gray)
//                .frame(maxWidth: .infinity, alignment: .center)
//                .padding()
//        } else if #available(iOS 16.0, *) {
//            Chart {
//                ForEach(chartData) { dataPoint in
//                    BarMark(
//                        x: .value("Date", dataPoint.date, unit: .day),
//                        y: .value("Hours", dataPoint.value)
//                    )
//                    .foregroundStyle(Color.blue.gradient)
//                }
//                
//                RuleMark(y: .value("Goal", 8))
//                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
//                    .foregroundStyle(.gray)
//                    .annotation(position: .trailing) {
//                        Text("Goal")
//                            .font(.caption)
//                            .foregroundColor(.gray)
//                    }
//            }
//            .chartYAxis {
//                AxisMarks(position: .leading)
//            }
//        } else {
//            // Fallback for iOS 15
//            HStack(alignment: .bottom, spacing: 8) {
//                ForEach(chartData) { dataPoint in
//                    VStack {
//                        Spacer()
//                        
//                        RoundedRectangle(cornerRadius: 4)
//                            .fill(Color.blue)
//                            .frame(width: 20, height: CGFloat(min(dataPoint.value * 20, 200)))
//                        
//                        Text(dateFormatter.string(from: dataPoint.date))
//                            .font(.caption2)
//                            .rotationEffect(.degrees(-45))
//                    }
//                }
//            }
//            .frame(height: 220)
//            .padding(.horizontal)
//        }
//    }
//    
//    private var dateFormatter: DateFormatter {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "MM/dd"
//        return formatter
//    }
//}
//
//struct WorkoutSummaryView: View {
//    let workouts: [HKWorkout]
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            Text("Recent Workouts")
//                .font(.headline)
//                .padding(.horizontal)
//            
//            ForEach(workouts.prefix(5), id: \.uuid) { workout in
//                WorkoutRowView(workout: workout)
//            }
//            
//            if workouts.count > 5 {
//                Text("+ \(workouts.count - 5) more workouts")
//                    .font(.caption)
//                    .foregroundColor(.gray)
//                    .frame(maxWidth: .infinity, alignment: .center)
//                    .padding(.top, 8)
//            }
//        }
//        .padding(.vertical, 16)
//        .background(Color(UIColor.secondarySystemBackground))
//        .cornerRadius(12)
//        .padding(.horizontal)
//    }
//}
//
//struct WorkoutRowView: View {
//    let workout: HKWorkout
//    
//    var workoutTypeIcon: String {
//        switch workout.workoutActivityType {
//        case .running:
//            return "figure.run"
//        case .cycling:
//            return "figure.outdoor.cycle"
//        case .walking:
//            return "figure.walk"
//        case .swimming:
//            return "figure.pool.swim"
//        case .yoga:
//            return "figure.mind.and.body"
//        case .functionalStrengthTraining:
//            return "dumbbell"
//        default:
//            return "figure.mixed.cardio"
//        }
//    }
//    
//    var workoutTypeName: String {
//        switch workout.workoutActivityType {
//        case .running:
//            return "Running"
//        case .cycling:
//            return "Cycling"
//        case .walking:
//            return "Walking"
//        case .swimming:
//            return "Swimming"
//        case .yoga:
//            return "Yoga"
//        case .functionalStrengthTraining:
//            return "Strength Training"
//        default:
//            return "Workout"
//        }
//    }
//    
//    var formattedDuration: String {
//        let hours = Int(workout.duration) / 3600
//        let minutes = (Int(workout.duration) % 3600) / 60
//        
//        if hours > 0 {
//            return "\(hours)h \(minutes)m"
//        } else {
//            return "\(minutes)m"
//        }
//    }
//    
//    var formattedDate: String {
//        let formatter = DateFormatter()
//        formatter.dateStyle = .medium
//        formatter.timeStyle = .short
//        return formatter.string(from: workout.startDate)
//    }
//    
//    var body: some View {
//        HStack(spacing: 12) {
//            Image(systemName: workoutTypeIcon)
//                .font(.system(size: 24))
//                .foregroundColor(.blue)
//                .frame(width: 36, height: 36)
//            
//            VStack(alignment: .leading, spacing: 4) {
//                Text(workoutTypeName)
//                    .font(.headline)
//                
//                Text(formattedDate)
//                    .font(.caption)
//                    .foregroundColor(.gray)
//            }
//            
//            Spacer()
//            
//            VStack(alignment: .trailing, spacing: 4) {
//                Text(formattedDuration)
//                    .font(.subheadline)
//                    .fontWeight(.semibold)
//                
//                if let calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) {
//                    Text("\(Int(calories)) cal")
//                        .font(.caption)
//                        .foregroundColor(.orange)
//                }
//            }
//        }
//        .padding(.horizontal)
//        .padding(.vertical, 8)
//    }
//}
//
//// MARK: - Helpers
//struct DataPoint: Identifiable {
//    let id = UUID()
//    let date: Date
//    let value: Double
//}
//
//struct FitnessChartSection<Content: View>: View {
//    let title: String
//    let content: Content
//    
//    init(title: String, @ViewBuilder content: () -> Content) {
//        self.title = title
//        self.content = content()
//    }
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            Text(title)
//                .font(.headline)
//                .padding(.horizontal)
//            
//            content
//                .frame(height: 220)
//                .padding(.horizontal, 8)
//        }
//        .padding(.vertical, 8)
//        .background(Color(UIColor.secondarySystemBackground))
//        .cornerRadius(12)
//        .padding(.horizontal)
//    }
//}
