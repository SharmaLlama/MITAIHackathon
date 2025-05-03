import CoreML
import Vision
import UIKit
import AVFoundation
import SwiftUI

// MARK: - Model Types
struct SkinConditionDetection {
    let boundingBox: CGRect
    let label: String
    let confidence: Float
}




    
class SkinAnalyser {
    private var acneClassModel: VNCoreMLModel?
    private let processingQueue = DispatchQueue(label: "com.skinsnap.mlprocessing", qos: .userInitiated)
    
    init() {
        setupModel()
    }
    
    private func setupModel() {
        // Load Core ML model - changed from yolo11m to AcneClassQuant
        guard let modelURL = Bundle.main.url(forResource: "AcneClassQuant", withExtension: "mlmodelc") else {
            print("Failed to find AcneClassQuant model file")
            return
        }
        
        do {
            // Create model instance
            let model = try MLModel(contentsOf: modelURL)
            // Convert to Vision friendly format
            acneClassModel = try VNCoreMLModel(for: model)
        } catch {
            print("Failed to load AcneClassQuant Core ML model: \(error.localizedDescription)")
        }
    }
    
    func analyseSkin(image: UIImage, completion: @escaping (SkinAnalysisResult?, Error?) -> Void) {
            guard let acneClassModel = acneClassModel else {
                completion(nil, NSError(domain: "SkinAnalyser", code: 1, userInfo: [NSLocalizedDescriptionKey: "Model not loaded"]))
                return
            }
            
            guard let cgImage = image.cgImage else {
                completion(nil, NSError(domain: "SkinAnalyser", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to get CGImage"]))
                return
            }
            
            // Resize image to 224x224 as required by the model
            let resizedImage = resizeImage(image: image, targetSize: CGSize(width: 224, height: 224))
            guard let resizedCGImage = resizedImage.cgImage else {
                completion(nil, NSError(domain: "SkinAnalyser", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to resize image"]))
                return
            }
            
            // Create Vision request with the AcneClassQuant model
            let request = VNCoreMLRequest(model: acneClassModel) { request, error in
                if let error = error {
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                    return
                }
                
                // For the new model, we expect multiarray outputs instead of object detections
                guard let results = request.results as? [VNCoreMLFeatureValueObservation] else {
                    DispatchQueue.main.async {
                        completion(nil, NSError(domain: "SkinAnalyser", code: 4, userInfo: [NSLocalizedDescriptionKey: "Unexpected result type"]))
                    }
                    return
                }
                
                // Process model output
                self.processingQueue.async {
                    let analysisResult = self.processAcneClassResults(results, for: image)
                    
                    DispatchQueue.main.async {
                        completion(analysisResult, nil)
                    }
                }
            }
            
            // Configure request
            request.imageCropAndScaleOption = .scaleFill
            
            // Create Vision image request handler
            let handler = VNImageRequestHandler(cgImage: resizedCGImage, options: [:])
            
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
    
    private func processAcneClassResults(_ observations: [VNCoreMLFeatureValueObservation], for image: UIImage) -> SkinAnalysisResult {
           var severityScore: Double = 0.0
           var lesionCount: Int = 0
           
           // Extract values from the model output
           for observation in observations {
               if observation.featureName == "severity" {
                   if let multiArray = observation.featureValue.multiArrayValue {
                       // Get severity score (0-4 scale)
                       if multiArray.count > 0 {
                           severityScore = Double(multiArray[0].doubleValue)
                       }
                   }
               } else if observation.featureName == "lesions" {
                   if let multiArray = observation.featureValue.multiArrayValue {
                       // Get lesion count
                       if multiArray.count > 0 {
                           lesionCount = Int(round(multiArray[0].doubleValue))
                       }
                   }
               }
           }
           
           // Convert severity score from 0-4 scale to 0-100 scale
           let normalizedSeverityScore = (severityScore / 4.0) * 100.0
           
           // Determine condition based on severity
           let condition = determineCondition(severityScore: severityScore)
           
           // Create affected areas based on severity
           let affectedAreas = createDefaultAffectedAreas(severityScore: severityScore, lesionCount: lesionCount)
           
           // Since we don't have bounding boxes, we'll create a placeholder detection
           let centerDetection = SkinConditionDetection(
               boundingBox: CGRect(x: 0.4, y: 0.4, width: 0.2, height: 0.2),
               label: condition,
               confidence: Float(severityScore / 4.0)
           )
           
           return SkinAnalysisResult(
               date: Date(),
               severityScore: normalizedSeverityScore,
               condition: condition,
               confidence: Float(severityScore / 4.0),
               affectedAreas: affectedAreas,
               detections: [centerDetection]
           )
       }
       
        
        // Resize image to target size (needed for the model's input requirements)
        private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
            let renderer = UIGraphicsImageRenderer(size: targetSize)
            return renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: targetSize))
            }
        }
    
    // Map severity score to a condition label
    private func determineCondition(severityScore: Double) -> String {
        switch severityScore {
        case 0..<1:
            return "Clear"
        case 1..<2:
            return "Mild Acne"
        case 2..<3:
            return "Moderate Acne"
        case 3..<4:
            return "Severe Acne"
        default:
            return "Very Severe Acne"
        }
    }
    
    // Create default affected areas based on severity and lesion count
    private func createDefaultAffectedAreas(severityScore: Double, lesionCount: Int) -> [FaceRegion] {
        let normalizedSeverity = severityScore / 4.0
        
        // Simplified affected areas generation based on severity score
        // In a real app, you'd need more sophisticated logic
        var regions: [FaceRegion] = []
        
        if normalizedSeverity > 0.1 {
            regions.append(FaceRegion(name: "Forehead", severity: min(1.0, normalizedSeverity * 1.2)))
        }
        
        if normalizedSeverity > 0.2 {
            regions.append(FaceRegion(name: "Cheeks", severity: min(1.0, normalizedSeverity * 1.1)))
        }
        
        if normalizedSeverity > 0.3 {
            regions.append(FaceRegion(name: "Chin", severity: min(1.0, normalizedSeverity * 0.9)))
        }
        
        if normalizedSeverity > 0.5 {
            regions.append(FaceRegion(name: "Nose", severity: min(1.0, normalizedSeverity * 0.8)))
        }
        
        return regions
    }
}
    
