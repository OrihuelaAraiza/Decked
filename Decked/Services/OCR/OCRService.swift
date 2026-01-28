//
//  OCRService.swift
//  Decked
//
//  On-device OCR using Vision framework
//

import Vision
import UIKit

// MARK: - OCR Service Protocol
protocol OCRServiceProtocol {
    func recognizeText(from image: UIImage) async throws -> [RecognizedText]
}

// MARK: - OCR Service
final class OCRService: OCRServiceProtocol {
    
    // MARK: - Properties
    
    /// Supported recognition languages
    private let recognitionLanguages = ["en-US", "es-ES", "ja-JP"]
    
    /// Minimum confidence threshold for text recognition
    private let minimumConfidence: Float = 0.3
    
    // MARK: - Public Methods
    
    /// Recognizes text from an image using Vision framework
    /// - Parameter image: The UIImage to process
    /// - Returns: Array of recognized text with confidence scores
    func recognizeText(from image: UIImage) async throws -> [RecognizedText] {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: OCRError.recognitionFailed(error.localizedDescription))
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let results = self.processObservations(observations)
                continuation.resume(returning: results)
            }
            
            // Configure request
            request.recognitionLevel = .accurate
            request.recognitionLanguages = recognitionLanguages
            request.usesLanguageCorrection = true
            request.automaticallyDetectsLanguage = true
            
            // Process image
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.recognitionFailed(error.localizedDescription))
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func processObservations(_ observations: [VNRecognizedTextObservation]) -> [RecognizedText] {
        var results: [RecognizedText] = []
        
        for observation in observations {
            guard let topCandidate = observation.topCandidates(1).first else { continue }
            
            let confidence = topCandidate.confidence
            guard confidence >= minimumConfidence else { continue }
            
            // Convert bounding box from Vision coordinates (bottom-left origin, normalized)
            // to UIKit coordinates (top-left origin)
            let boundingBox = observation.boundingBox
            let normalizedBox = CGRect(
                x: boundingBox.origin.x,
                y: 1 - boundingBox.origin.y - boundingBox.height,
                width: boundingBox.width,
                height: boundingBox.height
            )
            
            let recognizedText = RecognizedText(
                text: normalizeText(topCandidate.string),
                confidence: confidence,
                boundingBox: normalizedBox
            )
            
            results.append(recognizedText)
        }
        
        // Sort by vertical position (top to bottom)
        results.sort { ($0.boundingBox?.origin.y ?? 0) < ($1.boundingBox?.origin.y ?? 0) }
        
        return results
    }
    
    /// Normalizes recognized text for better parsing
    private func normalizeText(_ text: String) -> String {
        var normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Fix common OCR mistakes
        normalized = normalized
            .replacingOccurrences(of: "O", with: "0", options: [], range: nil)
            .replacingOccurrences(of: "l", with: "1", options: [], range: normalized.range(of: "\\d+[l]\\d+", options: .regularExpression))
        
        // Clean up extra whitespace
        while normalized.contains("  ") {
            normalized = normalized.replacingOccurrences(of: "  ", with: " ")
        }
        
        return normalized
    }
}

// MARK: - OCR Errors
enum OCRError: LocalizedError {
    case invalidImage
    case recognitionFailed(String)
    case noTextFound
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format for OCR processing."
        case .recognitionFailed(let reason):
            return "Text recognition failed: \(reason)"
        case .noTextFound:
            return "No text detected in image."
        }
    }
}

// MARK: - OCR Service Extension for Batch Processing
extension OCRService {
    
    /// Process multiple images in parallel
    func recognizeTextBatch(from images: [UIImage]) async throws -> [[RecognizedText]] {
        try await withThrowingTaskGroup(of: (Int, [RecognizedText]).self) { group in
            for (index, image) in images.enumerated() {
                group.addTask {
                    let results = try await self.recognizeText(from: image)
                    return (index, results)
                }
            }
            
            var results: [[RecognizedText]] = Array(repeating: [], count: images.count)
            
            for try await (index, texts) in group {
                results[index] = texts
            }
            
            return results
        }
    }
}
