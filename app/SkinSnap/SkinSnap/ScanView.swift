import SwiftUI
import AVFoundation
import SwiftData

struct ScanView: View {
    @StateObject private var viewModel = ScanViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var showCameraView = false
    @State private var showResultView = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if let image = viewModel.capturedImage {
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
                        SkinResultPreview(result: result)
                            .padding()
                    }
                    
                    Button(action: {
                        viewModel.capturedImage = nil
                        viewModel.analysisResult = nil
                    }) {
                        Text("Take New Photo")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    
                    if let result = viewModel.analysisResult {
                        NavigationLink(destination: DetailedResultView(analysisResult: result)) {
                            Text("Save and Continue")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            saveResult(result: result)
                        })
                        .padding(.top, 8)
                    }
                } else {
                    Spacer()
                    
                    VStack(spacing: 20) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 70))
                            .foregroundColor(.blue)
                        
                        Text("Take a photo to analyse your skin")
                            .font(.headline)
                        
                        Text("Position your face clearly in the frame with good lighting")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showCameraView = true
                    }) {
                        Text("Take Photo")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    .padding(.bottom, 32)
                }
            }
            .sheet(isPresented: $showCameraView) {
                CameraView(isShown: $showCameraView, image: $viewModel.capturedImage, onImageCaptured: { image in
                    viewModel.analyseImage(image)
                })
            }
            .navigationTitle("Skin Scanner")
//            .navigationDestination(isPresented: $showResultView) {
//                if let result = viewModel.analysisResult {
//                    DetailedResultView(analysisResult: result)
//                }
//            }
        }
    }
    
    // Save analysis result to Swift Data
    private func saveResult(result: SkinAnalysisResult) {
        // Create image data from capturedImage
        let imageData = viewModel.capturedImage?.jpegData(compressionQuality: 0.7)
        
        // Convert the analysis result to a SwiftData model
        let skinEntry = result.toSkinEntry(imageData: imageData)
        
        // Save to Swift Data
        modelContext.insert(skinEntry)
        try? modelContext.save()
        
        print("Result saved to Swift Data")
    }
}

// ViewModel for the ScanView
class ScanViewModel: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var isAnalyzing = false
    @Published var analysisResult: SkinAnalysisResult?
    
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

// Preview of analysis result
struct SkinResultPreview: View {
    let result: SkinAnalysisResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Analysis Results")
                .font(.headline)
                .padding(.bottom, 4)
            
            HStack {
                Text("Severity Score:")
                    .fontWeight(.medium)
                Spacer()
                Text("\(Int(result.severityScore))/100")
                    .foregroundColor(severityColor(score: result.severityScore))
                    .fontWeight(.bold)
            }
            
            HStack {
                Text("Condition:")
                    .fontWeight(.medium)
                Spacer()
                Text(result.condition)
            }
            
            HStack {
                Text("Confidence:")
                    .fontWeight(.medium)
                Spacer()
                Text("\(Int(result.confidence * 100))%")
            }
            
            Text("Affected Areas:")
                .fontWeight(.medium)
                .padding(.top, 4)
            
            ForEach(result.affectedAreas, id: \.name) { area in
                HStack {
                    Text(area.name)
                    Spacer()
                    ProgressView(value: area.severity)
                        .progressViewStyle(LinearProgressViewStyle(tint: severityColor(score: area.severity * 100)))
                        .frame(width: 100)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func severityColor(score: Double) -> Color {
        switch score {
        case 0..<25: return .green
        case 25..<50: return .yellow
        case 50..<75: return .orange
        default: return .red
        }
    }
}

// Detail result view - would be expanded in a real app
struct DetailedResultView: View {
    let analysisResult: SkinAnalysisResult
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Severity Score
                VStack(alignment: .leading, spacing: 8) {
                    Text("Severity Score")
                        .font(.headline)
                    
                    HStack {
                        Text("\(Int(analysisResult.severityScore))")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(severityColor(score: analysisResult.severityScore))
                        
                        Text("/ 100")
                            .font(.title3)
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                    }
                    
                    // Severity label
                    Text(severityLabel(score: analysisResult.severityScore))
                        .font(.subheadline)
                        .foregroundColor(severityColor(score: analysisResult.severityScore))
                        .padding(.vertical, 4)
                        .padding(.horizontal, 12)
                        .background(severityColor(score: analysisResult.severityScore).opacity(0.1))
                        .cornerRadius(8)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                
                // Affected Areas
                VStack(alignment: .leading, spacing: 8) {
                    Text("Affected Areas")
                        .font(.headline)
                    
                    ForEach(analysisResult.affectedAreas, id: \.name) { area in
                        HStack {
                            Text(area.name)
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text("\(Int(area.severity * 100))%")
                                .font(.subheadline)
                                .foregroundColor(severityColor(score: area.severity * 100))
                        }
                        .padding(.vertical, 8)
                        
                        ProgressView(value: area.severity)
                            .progressViewStyle(LinearProgressViewStyle(tint: severityColor(score: area.severity * 100)))
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                
                // Recommendations (placeholder)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommendations")
                        .font(.headline)
                    
                    Text("Based on your scan results, consider the following tips:")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        recommendationRow(icon: "drop.fill", text: "Stay hydrated. Drink at least 8 glasses of water daily.")
                        recommendationRow(icon: "zzz", text: "Ensure you get 7-8 hours of quality sleep.")
                        recommendationRow(icon: "hand.raised.fill", text: "Avoid touching your face throughout the day.")
                        recommendationRow(icon: "sun.max.fill", text: "Use SPF 30+ sunscreen daily, even indoors.")
                    }
                    .padding(.top, 4)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            }
            .padding()
        }
        .navigationTitle("Analysis Details")
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
    
    private func severityColor(score: Double) -> Color {
        switch score {
        case 0..<25: return .green
        case 25..<50: return .yellow
        case 50..<75: return .orange
        default: return .red
        }
    }
    
    private func severityLabel(score: Double) -> String {
        switch score {
        case 0..<25: return "Mild"
        case 25..<50: return "Moderate"
        case 50..<75: return "Significant"
        default: return "Severe"
        }
    }
}
