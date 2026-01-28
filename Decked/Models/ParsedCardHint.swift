//
//  ParsedCardHint.swift
//  Decked
//
//  Models for OCR parsing results
//

import Foundation

// MARK: - Recognized Text
/// Raw text recognized by OCR with confidence
struct RecognizedText: Identifiable, Hashable {
    let id = UUID()
    let text: String
    let confidence: Float
    let boundingBox: CGRect?
    
    var isHighConfidence: Bool {
        confidence >= 0.7
    }
    
    var normalizedText: String {
        text.uppercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "  ", with: " ")
    }
}

// MARK: - Parsed Card Hint
/// Extracted information from OCR text for card identification
struct ParsedCardHint: Hashable {
    var nameGuess: String?
    var numberGuess: String?
    var setNumberGuess: String? // Total cards in set (e.g., "198" from "123/198")
    var rarityGuess: CardRarity?
    var rawLines: [String]
    var language: CardLanguage?
    var hp: String?
    var types: [String]?
    
    var isEmpty: Bool {
        nameGuess == nil && numberGuess == nil && rarityGuess == nil
    }
    
    var hasStrongHint: Bool {
        numberGuess != nil || (nameGuess != nil && nameGuess!.count >= 3)
    }
    
    /// Formatted display string for debugging/preview
    var debugDescription: String {
        var parts: [String] = []
        if let name = nameGuess { parts.append("Name: \(name)") }
        if let number = numberGuess { parts.append("Number: \(number)") }
        if let rarity = rarityGuess { parts.append("Rarity: \(rarity.rawValue)") }
        if let hp = hp { parts.append("HP: \(hp)") }
        return parts.isEmpty ? "No hints detected" : parts.joined(separator: " | ")
    }
}

// MARK: - Scan Result
/// Complete result from a scan session
struct ScanResult: Identifiable {
    let id = UUID()
    let timestamp: Date
    let recognizedTexts: [RecognizedText]
    let parsedHint: ParsedCardHint
    let processingTimeMs: Int
    
    init(
        timestamp: Date = Date(),
        recognizedTexts: [RecognizedText],
        parsedHint: ParsedCardHint,
        processingTimeMs: Int = 0
    ) {
        self.timestamp = timestamp
        self.recognizedTexts = recognizedTexts
        self.parsedHint = parsedHint
        self.processingTimeMs = processingTimeMs
    }
}

// MARK: - Scanner State
enum ScannerState: Equatable {
    case idle
    case scanning
    case processing
    case cardDetected(ParsedCardHint)
    case error(String)
    
    var statusText: String {
        switch self {
        case .idle:
            return "Ready to scan"
        case .scanning:
            return "Scanning..."
        case .processing:
            return "Processing..."
        case .cardDetected:
            return "Card detected"
        case .error(let message):
            return message
        }
    }
    
    var isActive: Bool {
        switch self {
        case .scanning, .processing:
            return true
        default:
            return false
        }
    }
}

// MARK: - Detection Region
/// Represents a detected text region in the camera frame
struct DetectionRegion: Identifiable {
    let id = UUID()
    let text: String
    let boundingBox: CGRect
    let confidence: Float
}
