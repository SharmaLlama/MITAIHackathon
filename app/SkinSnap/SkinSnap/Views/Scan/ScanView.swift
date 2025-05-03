import SwiftUI
import AVFoundation
import SwiftData
import PhotosUI
struct ScanView: View {
    @StateObject private var viewModel = ScanViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var showCameraView = false
    @State private var showResultView = false
    @State private var selectedDate = Date()
    @State private var showHistoricalResults = false
    @State private var isAddingNewPhoto = false // New state to track when adding a new photo
    
    // Check if selected date is today
    private var isCurrentDate: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
    
    // Check if there's an existing entry for selected date
    private var hasExistingEntry: Bool {
        viewModel.historicalResults[selectedDate.startOfDay] != nil
    }
    
    var body: some View {
        NavigationStack {
            // Wrap in ScrollView to ensure content is always scrollable
            ScrollView {
                VStack(spacing: 20) {
                    // Date Selector
                    DatePicker(
                        "Select Date",
                        selection: $selectedDate,
                        in: ...Date(),  // Only allow dates up to today
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .padding()
                    .onChange(of: selectedDate) { _, newValue in
                        // Always check for historical data when date changes
                        let hasHistoricalData = viewModel.historicalResults[newValue.startOfDay] != nil
                        
                        // Only show historical results if we're not actively adding a new photo
                        // and there's historical data for the selected date
                        if !isAddingNewPhoto && hasHistoricalData {
                            showHistoricalResults = true
                            viewModel.resetView()
                        } else if !hasHistoricalData {
                            // No data exists for this date, so we can start fresh
                            showHistoricalResults = false
                            viewModel.resetView()
                        }
                        // If we're adding a new photo, maintain that state
                    }
                    
                    if showHistoricalResults {
                        // Show historical results view
                        if let historicalEntry = viewModel.historicalResults[selectedDate.startOfDay] {
                            VStack {
                                if let imageData = historicalEntry.imageData,
                                   let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 300)
                                        .cornerRadius(12)
                                        .padding()
                                } else {
                                    Text("No image available for this date")
                                        .foregroundColor(.gray)
                                        .padding()
                                }
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Saved Analysis Results")
                                        .font(.headline)
                                    
                                    HStack {
                                        Text("Severity Score:")
                                        Spacer()
                                        Text("\(Int(historicalEntry.severityScore))/100")
                                            .foregroundColor(healthColor(score: historicalEntry.severityScore))
                                            .fontWeight(.bold)
                                    }
                                    
                                    HStack {
                                        Text("Condition:")
                                        Spacer()
                                        Text(historicalEntry.condition)
                                    }
                                    
                                    if historicalEntry.lesionCount > 0 {
                                        HStack {
                                            Text("Lesion Count:")
                                            Spacer()
                                            Text("\(historicalEntry.lesionCount)")
                                                .fontWeight(.medium)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(12)
                                .padding(.horizontal)
                                
                                Button(action: {
                                    showHistoricalResults = false
                                    isAddingNewPhoto = true // Set this flag when adding a new photo
                                    viewModel.resetView()
                                }) {
                                    Text("Add New Analysis for This Date")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                        .padding(.horizontal)
                                }
                                .padding(.top)
                                
                                // Add extra padding at the bottom to prevent overlap with tab bar
                                Spacer()
                                    .frame(height: 60)
                            }
                        }
                    } else if let image = viewModel.capturedImage {
                        // Standard analysis view for newly captured/uploaded image
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 400)
                            .cornerRadius(12)
                            .padding()
                        
                        if viewModel.isAnalyzing {
                            ProgressView("Analyzing skin condition...")
                                .padding()
                        } else if let result = viewModel.analysisResult {
                            // Navigate to detailed result view when analysis is complete
                            NavigationLink(destination: DetailedResultView(
                                analysisResult: result,
                                image: image,
                                selectedDate: selectedDate,
                                onSave: {
                                    saveResult(result: result)
                                    isAddingNewPhoto = false // Reset after saving
                                }
                            )) {
                                Text("View Analysis Results")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                            }
                        }
                        
                        Button(action: {
                            viewModel.capturedImage = nil
                            viewModel.analysisResult = nil
                        }) {
                            Text("Start Over")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                        
                        // Add extra padding at the bottom to prevent overlap with tab bar
                        Spacer()
                            .frame(height: 60)
                    } else {
                        Spacer()
                        
                        VStack(spacing: 20) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 70))
                                .foregroundColor(.blue)
                            
                            Text(isCurrentDate ?
                                 "Take or upload a photo to analyse your skin" :
                                 "Upload a photo to analyse your skin history")
                                .font(.headline)
                            
                            Text(isCurrentDate ?
                                 "Position your face clearly in the frame with good lighting" :
                                 "Select a photo from your library for the selected date")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 16) {
                            // Only show camera button for current date
                            if isCurrentDate {
                                Button(action: {
                                    showCameraView = true
                                }) {
                                    HStack {
                                        Image(systemName: "camera")
                                            .font(.system(size: 18))
                                        Text("Take Photo")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                                }
                            }
                            
                            Button(action: {
                                viewModel.showImagePicker = true
                            }) {
                                HStack {
                                    Image(systemName: "photo.on.rectangle")
                                        .font(.system(size: 18))
                                    Text("Upload Photo")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .padding(.horizontal)
                            }
                        }
                        .padding(.bottom, 80) // Increased padding to avoid tab bar overlap
                    }
                }
                .padding(.vertical)
            }
            .sheet(isPresented: $showCameraView) {
                CameraView(isShown: $showCameraView, image: $viewModel.capturedImage, onImageCaptured: { image in
                    viewModel.analyseImage(image)
                    isAddingNewPhoto = true // Set this flag when adding a new photo
                })
            }
            .sheet(isPresented: $viewModel.showImagePicker) {
                PhotoPicker(image: $viewModel.capturedImage, onImageSelected: { image in
                    if let image = image {
                        viewModel.analyseImage(image)
                        isAddingNewPhoto = true // Set this flag when adding a new photo
                    }
                })
            }
            .navigationTitle("Skin Scanner")
            .onAppear {
                viewModel.loadHistoricalEntries(modelContext: modelContext)
                // Check if there's data for the current date
                if !isAddingNewPhoto && viewModel.historicalResults[selectedDate.startOfDay] != nil {
                    showHistoricalResults = true
                }
            }
        }
    }
    
    // Save analysis result to Swift Data
    private func saveResult(result: SkinAnalysisResult) {
        // Create image data from capturedImage
        let imageData = viewModel.capturedImage?.jpegData(compressionQuality: 0.7)
        
        // Convert the analysis result to a SwiftData model with the selected date
        let updatedResult = SkinAnalysisResult(
            date: selectedDate, // Use selected date instead of current date
            severityScore: result.severityScore,
            condition: result.condition,
            confidence: result.confidence,
            affectedAreas: result.affectedAreas,
            lesionCount: result.lesionCount
        )
        
        let skinEntry = updatedResult.toSkinEntry(imageData: imageData)
        
        // Check if entry already exists for this date and delete it
        if let existingEntry = viewModel.historicalResults[selectedDate.startOfDay] {
            modelContext.delete(existingEntry)
        }
        
        // Save to Swift Data
        modelContext.insert(skinEntry)
        try? modelContext.save()
        
        print("Result saved to Swift Data for date: \(selectedDate)")
        
        // Refresh the historical data after saving
        viewModel.loadHistoricalEntries(modelContext: modelContext)
    }
    
    private func healthColor(score: Double) -> Color {
        switch score {
        case 0..<25: return .red
        case 25..<50: return .orange
        case 50..<75: return .yellow
        default: return .green
        }
    }
}

// The ViewModel, CameraView, PhotoPicker, and DetailedResultView remain unchanged

// ViewModel for the ScanView
class ScanViewModel: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var isAnalyzing = false
    @Published var analysisResult: SkinAnalysisResult?
    @Published var showImagePicker: Bool = false
    @Published var historicalResults: [Date: SkinEntry] = [:]
    
    private let skinAnalyser = SkinAnalyser()
    
    func analyseImage(_ image: UIImage) {
        isAnalyzing = true
        
        skinAnalyser.analyseSkin(image: image) { [weak self] result, error in
            guard let self = self else { return }
            
            self.isAnalyzing = false
            
            if let error = error {
                print("Analysis error: \(error.localizedDescription)")
                return
            }
            
            if let result = result {
                self.analysisResult = result
            }
        }
    }
    
    func resetView() {
        capturedImage = nil
        analysisResult = nil
        isAnalyzing = false
    }
    
    // Load all historical entries from SwiftData
    func loadHistoricalEntries(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<SkinEntry>()
        
        do {
            let entries = try modelContext.fetch(descriptor)
            // Create a dictionary mapping dates to entries
            historicalResults = Dictionary(uniqueKeysWithValues: entries.map { entry in
                (entry.date.startOfDay, entry)
            })
        } catch {
            print("Error fetching skin entries: \(error.localizedDescription)")
        }
    }
}

// Extension to get start of day for date comparison
extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}

// Camera UI using AVFoundation
struct CameraView: UIViewControllerRepresentable {
    @Binding var isShown: Bool
    @Binding var image: UIImage?
    var onImageCaptured: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.cameraDevice = .front // Use front camera for selfies
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
                parent.onImageCaptured(uiImage)
            }
            parent.isShown = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isShown = false
        }
    }
}

// Photo picker using PhotosUI
struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var onImageSelected: (UIImage?) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider else {
                parent.onImageSelected(nil)
                return
            }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                    DispatchQueue.main.async {
                        guard let self = self, let image = image as? UIImage else {
                            self?.parent.onImageSelected(nil)
                            return
                        }
                        
                        self.parent.image = image
                        self.parent.onImageSelected(image)
                    }
                }
            }
        }
    }
}

struct DetailedResultView: View {
    let analysisResult: SkinAnalysisResult
    let image: UIImage
    let selectedDate: Date
    let onSave: () -> Void
    @Environment(\.presentationMode) var presentationMode
    @State private var showingSaveConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Selected date
                Text(dateFormatter.string(from: selectedDate))
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                // Display captured image
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .cornerRadius(12)
                    .padding(.horizontal)
                
                // Analysis Results Card
                VStack(spacing: 24) {
                    // Skin Health Score with circular progress
                    VStack(spacing: 8) {
                        Text("Skin Health Score")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 30) {
                            ZStack {
                                Circle()
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                                    .frame(width: 100, height: 100)
                                
                                Circle()
                                    .trim(from: 0, to: CGFloat(analysisResult.severityScore / 100))
                                    .stroke(healthColor(score: analysisResult.severityScore), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                                    .frame(width: 100, height: 100)
                                    .rotationEffect(.degrees(-90))
                                
                                VStack {
                                    Text("\(Int(analysisResult.severityScore))")
                                        .font(.system(size: 32, weight: .bold))
                                    Text("/ 100")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text(healthLabel(score: analysisResult.severityScore))
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(healthColor(score: analysisResult.severityScore))
                                
                                Text(analysisResult.condition)
                                    .font(.body)
                                
                                Text("Confidence: \(Int(analysisResult.confidence * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // Lesion Count
                    VStack(spacing: 8) {
                        Text("Lesion Count")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack {
                            Image(systemName: "circle.hexagongrid.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.orange)
                            
                            VStack(alignment: .leading) {
                                Text("\(analysisResult.lesionCount)")
                                    .font(.system(size: 32, weight: .bold))
                                
                                Text("Detected acne lesions")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.leading, 8)
                            
                            Spacer()
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // Affected Areas - replaced with line chart
                    if #available(iOS 16.0, *) {
                        AffectedAreasLineChart(affectedAreas: analysisResult.affectedAreas)
                            .padding(.horizontal, 8)
                    } else {
                        AffectedAreasLegacyChart(affectedAreas: analysisResult.affectedAreas)
                            .padding(.horizontal, 8)
                    }
                    
                    Divider()
                    
                    // Recommendations
                    VStack(spacing: 10) {
                        Text("Recommendations")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            recommendationRow(icon: "drop.fill", text: generateHydrationRecommendation(health: analysisResult.severityScore))
                            recommendationRow(icon: "hand.raised.fill", text: "Avoid touching your face to prevent spreading bacteria.")
                            recommendationRow(icon: "bed.double.fill", text: "Ensure you get 7-8 hours of quality sleep.")
                            recommendationRow(icon: "sun.max.fill", text: "Apply SPF 30+ sunscreen daily.")
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 20)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Save Button
                Button(action: {
                    onSave()
                    showingSaveConfirmation = true
                    
                    // Dismiss after showing confirmation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    Text("Save Results")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("Analysis Results")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(
            ZStack {
                if showingSaveConfirmation {
                    VStack {
                        Spacer()
                        
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title)
                            
                            Text("Results saved for \(dateFormatter.string(from: selectedDate))")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                        .padding(.bottom, 40)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showingSaveConfirmation)
        )
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    private func recommendationRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            Text(text)
                .font(.subheadline)
        }
    }
    
    private func healthColor(score: Double) -> Color {
        switch score {
        case 0..<25: return .red
        case 25..<50: return .orange
        case 50..<75: return .yellow
        default: return .green
        }
    }
    
    private func healthLabel(score: Double) -> String {
        switch score {
        case 0..<25: return "Poor"
        case 25..<50: return "Fair"
        case 50..<75: return "Good"
        default: return "Excellent"
        }
    }
    
    private func generateHydrationRecommendation(health: Double) -> String {
        if health < 25 {
            return "Increase hydration to 10+ glasses daily to help reduce inflammation."
        } else if health < 50 {
            return "Drink 8-10 glasses of water daily to improve skin hydration."
        } else {
            return "Maintain hydration with at least 8 glasses of water daily."
        }
    }
}
