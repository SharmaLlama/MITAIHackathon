import CoreML
import Vision
import UIKit

class SkinAnalyser {
    private var skinConditionModel: VNCoreMLModel?
    private let processingQueue = DispatchQueue(label: "com.skinsnap.mlprocessing", qos: .userInitiated)
    
    init() {
        setupModel()
    }
    
    private func setupModel() {
        // Load Core ML model
        guard let modelURL = Bundle.main.url(forResource: "SkinModel", withExtension: "mlmodelc") else {
            print("Failed to find model file")
            return
        }
        
        do {
            // Create model instance
            let model = try MLModel(contentsOf: modelURL)
            // Convert to Vision friendly format
            skinConditionModel = try VNCoreMLModel(for: model)
        } catch {
            print("Failed to load Core ML model: \(error.localizedDescription)")
        }
    }
    
    func analyseSkin(image: UIImage, completion: @escaping (SkinAnalysisResult?, Error?) -> Void) {
        guard let skinConditionModel = skinConditionModel else {
            completion(nil, NSError(domain: "Skinanalyser", code: 1, userInfo: [NSLocalizedDescriptionKey: "Model not loaded"]))
            return
        }
        
        guard let cgImage = image.cgImage else {
            completion(nil, NSError(domain: "Skinanalyser", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to get CGImage"]))
            return
        }
        
        // Create Vision request with the model
        let request = VNCoreMLRequest(model: skinConditionModel) { request, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            guard let results = request.results as? [VNClassificationObservation] else {
                DispatchQueue.main.async {
                    completion(nil, NSError(domain: "Skinanalyser", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unexpected result type"]))
                }
                return
            }
            
            // Process model output
            self.processingQueue.async {
                // Create a skin analysis result from the Vision observations
                let analysisResult = self.processObservations(results, for: image)
                
                DispatchQueue.main.async {
                    completion(analysisResult, nil)
                }
            }
        }
        
        // Configure request
        request.imageCropAndScaleOption = .centerCrop
        
        // Create Vision image request handler
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        // Perform request
        processingQueue.async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
    }
    
    // Process the Vision observations into usable results
    private func processObservations(_ observations: [VNClassificationObservation], for image: UIImage) -> SkinAnalysisResult {
        // Extract severity score, classifications, etc.
        // TODO: need to build this
        
        let topObservation = observations.first ?? VNClassificationObservation()
        
        let severityScore = calculateSeverityScore(from: observations)
        let areas = detectAffectedAreas(from: image)
        
        return SkinAnalysisResult(
            date: Date(),
            severityScore: severityScore,
            condition: topObservation.identifier,
            confidence: topObservation.confidence,
            affectedAreas: areas
        )
    }
    
    // Calculate overall severity based on model output
    private func calculateSeverityScore(from observations: [VNClassificationObservation]) -> Double {
        // TODO: Replace with actual severity calculation logic
        
        // Here we just use the confidence of the top classification as the severity
        if let acneSevere = observations.first(where: { $0.identifier.contains("severe") }) {
            return Double(acneSevere.confidence) * 100
        } else if let acneModerate = observations.first(where: { $0.identifier.contains("moderate") }) {
            return Double(acneModerate.confidence) * 75
        } else if let acneMild = observations.first(where: { $0.identifier.contains("mild") }) {
            return Double(acneMild.confidence) * 50
        } else {
            return Double(observations.first?.confidence ?? 0) * 25
        }
    }
    
    // Detect affected face areas (could use facial landmarks + model output)
    private func detectAffectedAreas(from image: UIImage) -> [FaceRegion] {
        // TODO: steps
        // 1. Detect face landmarks using Vision
        // 2. Map model outputs to specific face regions
        // 3. Return affected regions with severity scores
        
        // This is just a placeholder
        return [
            FaceRegion(name: "Forehead", severity: 0.5),
            FaceRegion(name: "Cheeks", severity: 0.3),
            FaceRegion(name: "Chin", severity: 0.7)
        ]
    }
}
