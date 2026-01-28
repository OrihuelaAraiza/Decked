//
//  CardTextParser.swift
//  Decked
//
//  Parses OCR text to extract card information hints
//

import Foundation

// MARK: - Card Text Parser Protocol
protocol CardTextParserProtocol {
    func parse(_ recognizedTexts: [RecognizedText]) -> ParsedCardHint
}

// MARK: - Card Text Parser
final class CardTextParser: CardTextParserProtocol {
    
    // MARK: - Patterns
    
    /// Pattern to match card numbers like "123/198", "001/165", "SV045/SV094"
    private let numberPattern = #"(\d{1,3})\s*/\s*(\d{1,3})"#
    private let svNumberPattern = #"(SV\d{1,3})\s*/\s*(SV\d{1,3})"#
    private let promoPattern = #"SWSH\d{1,3}|SM\d{1,3}|XY\d{1,3}"#
    
    /// Pattern to match HP values
    private let hpPattern = #"(\d{2,3})\s*HP"#
    
    /// Rarity keywords with their mappings
    private let rarityKeywords: [String: CardRarity] = [
        // English
        "COMMON": .common,
        "UNCOMMON": .uncommon,
        "RARE": .rare,
        "HOLO RARE": .holo,
        "RARE HOLO": .holo,
        "ULTRA RARE": .ultraRare,
        "SECRET RARE": .secretRare,
        "SPECIAL ART RARE": .specialArt,
        "ILLUSTRATION RARE": .illustrationRare,
        "HYPER RARE": .secretRare,
        "DOUBLE RARE": .rare,
        // Abbreviations
        "SR": .secretRare,
        "UR": .ultraRare,
        "SAR": .specialArt,
        "SIR": .specialArt,
        "IR": .illustrationRare,
        "AR": .illustrationRare,
        "HR": .secretRare,
        "RR": .rare,
        "RH": .holo,
        // Japanese
        "シークレット": .secretRare,
        "ウルトラ": .ultraRare,
        "スペシャル": .specialArt,
        // Spanish
        "RARA": .rare,
        "RARA HOLO": .holo,
        "ULTRA RARA": .ultraRare,
        "SECRETA": .secretRare
    ]
    
    /// Pokémon type keywords for better detection
    private let typeKeywords = [
        "GRASS", "FIRE", "WATER", "LIGHTNING", "PSYCHIC", "FIGHTING",
        "DARKNESS", "METAL", "FAIRY", "DRAGON", "COLORLESS", "NORMAL",
        // Spanish
        "PLANTA", "FUEGO", "AGUA", "RAYO", "PSÍQUICO", "LUCHA",
        "OSCURIDAD", "METAL", "HADA", "DRAGÓN", "INCOLORO",
        // Japanese
        "草", "炎", "水", "雷", "超", "闘", "悪", "鋼", "フェアリー", "ドラゴン", "無"
    ]
    
    /// Common words to filter out from name detection
    private let filterWords = Set([
        "THE", "AND", "OF", "A", "AN", "TO", "HP", "EX", "GX", "V", "VMAX", "VSTAR",
        "BASIC", "STAGE", "EVOLVES", "FROM", "TRAINER", "ITEM", "SUPPORTER",
        "WEAKNESS", "RESISTANCE", "RETREAT", "COST", "ABILITY", "ATTACK",
        "©", "POKEMON", "POKÉMON", "NINTENDO", "CREATURES", "GAME FREAK",
        // Spanish
        "EL", "LA", "LOS", "LAS", "DE", "DEL", "UN", "UNA", "Y", "BÁSICO",
        "ETAPA", "EVOLUCIONA", "DESDE", "ENTRENADOR", "OBJETO", "SEGUIDOR",
        // Japanese
        "ポケモン", "たね", "進化", "特性", "ワザ", "にげる"
    ])
    
    // MARK: - Public Methods
    
    func parse(_ recognizedTexts: [RecognizedText]) -> ParsedCardHint {
        let rawLines = recognizedTexts.map { $0.text }
        let combinedText = rawLines.joined(separator: " ").uppercased()
        
        var hint = ParsedCardHint(rawLines: rawLines)
        
        // Extract card number
        hint.numberGuess = extractCardNumber(from: combinedText)
        hint.setNumberGuess = extractSetTotal(from: combinedText)
        
        // Extract HP
        hint.hp = extractHP(from: combinedText)
        
        // Extract rarity
        hint.rarityGuess = extractRarity(from: combinedText)
        
        // Extract types
        hint.types = extractTypes(from: combinedText)
        
        // Detect language
        hint.language = detectLanguage(from: rawLines)
        
        // Extract name (using heuristics)
        hint.nameGuess = extractName(from: recognizedTexts)
        
        return hint
    }
    
    // MARK: - Private Extraction Methods
    
    private func extractCardNumber(from text: String) -> String? {
        // Try SV format first
        if let match = text.range(of: svNumberPattern, options: .regularExpression) {
            let fullMatch = String(text[match])
            let components = fullMatch.components(separatedBy: "/")
            if let first = components.first {
                return first.trimmingCharacters(in: .whitespaces)
            }
        }
        
        // Try promo format
        if let match = text.range(of: promoPattern, options: .regularExpression) {
            return String(text[match])
        }
        
        // Try standard format
        if let match = text.range(of: numberPattern, options: .regularExpression) {
            let fullMatch = String(text[match])
            let components = fullMatch.components(separatedBy: "/")
            if let first = components.first {
                // Pad to 3 digits
                let cleaned = first.trimmingCharacters(in: .whitespaces)
                if let num = Int(cleaned) {
                    return String(format: "%03d", num)
                }
                return cleaned
            }
        }
        
        return nil
    }
    
    private func extractSetTotal(from text: String) -> String? {
        if let match = text.range(of: numberPattern, options: .regularExpression) {
            let fullMatch = String(text[match])
            let components = fullMatch.components(separatedBy: "/")
            if components.count >= 2 {
                return components[1].trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }
    
    private func extractHP(from text: String) -> String? {
        if let match = text.range(of: hpPattern, options: .regularExpression) {
            let fullMatch = String(text[match])
            // Extract just the number
            let numbers = fullMatch.components(separatedBy: CharacterSet.decimalDigits.inverted)
                .filter { !$0.isEmpty }
            return numbers.first
        }
        return nil
    }
    
    private func extractRarity(from text: String) -> CardRarity? {
        // Check for exact matches first (longer phrases)
        let sortedKeywords = rarityKeywords.keys.sorted { $0.count > $1.count }
        
        for keyword in sortedKeywords {
            if text.contains(keyword) {
                return rarityKeywords[keyword]
            }
        }
        
        // Check for rarity based on card number patterns
        // Secret rares often have numbers higher than set total
        if let numberMatch = text.range(of: numberPattern, options: .regularExpression) {
            let fullMatch = String(text[numberMatch])
            let components = fullMatch.components(separatedBy: "/")
            if components.count == 2,
               let cardNum = Int(components[0].trimmingCharacters(in: .whitespaces)),
               let setTotal = Int(components[1].trimmingCharacters(in: .whitespaces)) {
                if cardNum > setTotal {
                    return .secretRare
                }
            }
        }
        
        return nil
    }
    
    private func extractTypes(from text: String) -> [String]? {
        var detectedTypes: [String] = []
        
        for type in typeKeywords {
            if text.contains(type) {
                detectedTypes.append(type)
            }
        }
        
        return detectedTypes.isEmpty ? nil : detectedTypes
    }
    
    private func detectLanguage(from lines: [String]) -> CardLanguage? {
        let combinedText = lines.joined(separator: " ")
        
        // Japanese detection (has Japanese characters)
        let japanesePattern = "[\\u3040-\\u309F\\u30A0-\\u30FF\\u4E00-\\u9FAF]"
        if combinedText.range(of: japanesePattern, options: .regularExpression) != nil {
            return .japanese
        }
        
        // Korean detection
        let koreanPattern = "[\\uAC00-\\uD7AF]"
        if combinedText.range(of: koreanPattern, options: .regularExpression) != nil {
            return .korean
        }
        
        // Chinese detection (simplified)
        let chinesePattern = "[\\u4E00-\\u9FFF]"
        if combinedText.range(of: chinesePattern, options: .regularExpression) != nil &&
           combinedText.range(of: japanesePattern, options: .regularExpression) == nil {
            return .chinese
        }
        
        // Spanish indicators
        let spanishWords = ["EVOLUCIONA", "DESDE", "BÁSICO", "ENTRENADOR", "ENERGÍA", "RETIRADA"]
        for word in spanishWords {
            if combinedText.uppercased().contains(word) {
                return .spanish
            }
        }
        
        // German indicators
        let germanWords = ["ENTWICKELT", "BASIS", "TRAINER", "ENERGIE"]
        for word in germanWords {
            if combinedText.uppercased().contains(word) {
                return .german
            }
        }
        
        // French indicators
        let frenchWords = ["ÉVOLUE", "ÉNERGIE", "DRESSEUR"]
        for word in frenchWords {
            if combinedText.uppercased().contains(word) {
                return .french
            }
        }
        
        // Default to English
        return .english
    }
    
    private func extractName(from recognizedTexts: [RecognizedText]) -> String? {
        // Heuristic: The card name is usually:
        // 1. Near the top of the card
        // 2. High confidence
        // 3. Not a common game term
        // 4. Before HP value
        
        let sortedTexts = recognizedTexts
            .filter { $0.isHighConfidence }
            .sorted { ($0.boundingBox?.origin.y ?? 0) < ($1.boundingBox?.origin.y ?? 0) }
        
        for text in sortedTexts.prefix(5) {
            let candidate = text.text
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased()
            
            // Skip if it's a filtered word
            if filterWords.contains(candidate) {
                continue
            }
            
            // Skip if it looks like a number pattern
            if candidate.range(of: #"^\d+$"#, options: .regularExpression) != nil {
                continue
            }
            
            // Skip if it's HP
            if candidate.contains("HP") || candidate.range(of: #"^\d+\s*HP"#, options: .regularExpression) != nil {
                continue
            }
            
            // Skip if too short
            if candidate.count < 3 {
                continue
            }
            
            // This might be the name
            // Clean it up
            var name = text.text.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Remove suffixes like "ex", "EX", "V", "VMAX", "VSTAR", "GX"
            let suffixes = [" EX", " GX", " V", " VMAX", " VSTAR", "-EX", "-GX"]
            var suffix = ""
            for s in suffixes {
                if name.uppercased().hasSuffix(s) {
                    suffix = s.trimmingCharacters(in: .whitespaces)
                    name = String(name.dropLast(s.count))
                    break
                }
            }
            
            // Capitalize properly
            name = name.capitalized
            
            // Add back suffix
            if !suffix.isEmpty {
                name += " " + suffix.uppercased()
            }
            
            return name
        }
        
        return nil
    }
}
