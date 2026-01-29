//
//  CardTextParser.swift
//  Decked
//
//  Parses OCR text to extract card information hints
//

import Foundation
import CoreGraphics

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

    /// Stop words/phrases to exclude descriptive lines from name detection
    private let nameStopWords = [
        "N.º", "N°", "POKÉMON", "POKEMON", "EVOLUCIONA", "EVOLUCIONA DE",
        "ALTURA", "DEBILIDAD", "RESISTENCIA", "RETIRADA", "SEGÚN",
        "NINTENDO", "CREATURES", "GAME FREAK"
    ]
    
    /// Hard stop words that must never be used as names
    private let hardStopWords = Set([
        "ABILITY", "TRAINER", "SUPPORTER", "ITEM", "STADIUM", "BASIC", "STAGE",
        "WEAKNESS", "RESISTANCE", "RETREAT", "ENERGY", "HP", "EVOLVES",
        "POKÉMON", "POKEMON", "ATTACK", "DAMAGE",
        // Spanish
        "HABILIDAD", "ENTRENADOR", "OBJETO", "ESTADIO", "DEBILIDAD",
        "RESISTENCIA", "RETIRADA", "ENERGÍA", "EVOLUCIONA"
    ])
    
    /// Attack-like keywords that should be mildly penalized
    private let attackLikeWords = [
        "GEM", "SLASH", "PUNCH", "BEAM", "BLAST", "SMASH", "KICK", "BITE",
        "CLAW", "TAIL", "STRIKE", "CHARGE", "RAY", "BURST", "EDGE", "CUT"
    ]

    private let pokemonNameSet: Set<String> = [
        "BULBASAUR","IVYSAUR","VENUSAUR","CHARMANDER","CHARMELEON","CHARIZARD",
        "SQUIRTLE","WARTORTLE","BLASTOISE","CATERPIE","METAPOD","BUTTERFREE",
        "WEEDLE","KAKUNA","BEEDRILL","PIDGEY","PIDGEOTTO","PIDGEOT",
        "RATTATA","RATICATE","SPEAROW","FEAROW","EKANS","ARBOK",
        "PIKACHU","RAICHU","SANDSHREW","SANDSLASH","NIDORAN","NIDORINA","NIDOQUEEN",
        "NIDORINO","NIDOKING","CLEFAIRY","CLEFABLE","VULPIX","NINETALES",
        "JIGGLYPUFF","WIGGLYTUFF","ZUBAT","GOLBAT","ODDISH","GLOOM","VILEPLUME",
        "PARAS","PARASECT","VENONAT","VENOMOTH","DIGLETT","DUGTRIO",
        "MEOWTH","PERSIAN","PSYDUCK","GOLDUCK","MANKEY","PRIMEAPE",
        "GROWLITHE","ARCANINE","POLIWAG","POLIWHIRL","POLIWRATH",
        "ABRA","KADABRA","ALAKAZAM","MACHOP","MACHOKE","MACHAMP",
        "BELLSPROUT","WEEPINBELL","VICTREEBEL","TENTACOOL","TENTACRUEL",
        "GEODUDE","GRAVELER","GOLEM","PONYTA","RAPIDASH","SLOWPOKE","SLOWBRO",
        "MAGNEMITE","MAGNETON","FARFETCHD","DODUO","DODRIO","SEEL","DEWGONG",
        "GRIMER","MUK","SHELLDER","CLOYSTER","GASTLY","HAUNTER","GENGAR",
        "ONIX","DROWZEE","HYPNO","KRABBY","KINGLER","VOLTORB","ELECTRODE",
        "EXEGGCUTE","EXEGGUTOR","CUBONE","MAROWAK","HITMONLEE","HITMONCHAN",
        "LICKITUNG","KOFFING","WEEZING","RHYHORN","RHYDON","CHANSEY",
        "TANGELA","KANGASKHAN","HORSEA","SEADRA","GOLDEEN","SEAKING",
        "STARYU","STARMIE","MR MIME","SCYTHER","JYNX","ELECTABUZZ","MAGMAR",
        "PINSIR","TAUROS","MAGIKARP","GYARADOS","LAPRAS","DITTO","EEVEE",
        "VAPOREON","JOLTEON","FLAREON","PORYGON","OMANYTE","OMASTAR",
        "KABUTO","KABUTOPS","AERODACTYL","SNORLAX","ARTICUNO","ZAPDOS",
        "MOLTRES","DRATINI","DRAGONAIR","DRAGONITE","MEWTWO","MEW"
    ]
    
    // MARK: - Public Methods
    
    func parse(_ recognizedTexts: [RecognizedText]) -> ParsedCardHint {
        let rawLines = recognizedTexts.map { $0.text }
        let combinedText = rawLines.joined(separator: " ").uppercased()
        
        var hint = ParsedCardHint(rawLines: rawLines)
        print("🧠 CardTextParser: rawLines: \(rawLines)")
        
        // Extract card number
        hint.numberGuess = extractCardNumber(from: combinedText)
        hint.setNumberGuess = extractSetTotal(from: combinedText)
        hint.setIdGuess = extractSetCode(from: rawLines, numberPattern: numberPattern)
        print("🧠 CardTextParser: numberGuess: \(hint.numberGuess ?? "nil") setNumberGuess: \(hint.setNumberGuess ?? "nil")")
        
        // Extract HP
        hint.hp = extractHP(from: combinedText)
        
        // Extract rarity
        hint.rarityGuess = extractRarity(from: combinedText)
        
        // Extract types
        hint.types = extractTypes(from: combinedText)
        
        // Detect language
        hint.language = detectLanguage(from: rawLines)
        
        // Extract name (using heuristics)
        let nameResult = extractName(from: recognizedTexts)
        hint.nameGuess = nameResult.name
        hint.nameFallbacks = nameResult.fallbacks
        
        if let setIdGuess = hint.setIdGuess {
            print("🧠 CardTextParser: setIdGuess: \(setIdGuess)")
        }
        
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

    private func extractSetCode(from rawLines: [String], numberPattern: String) -> String? {
        let lineInfos = rawLines.enumerated().map { (index: $0.offset, text: $0.element) }
        let linesWithNumber = lineInfos.filter { info in
            info.text.range(of: numberPattern, options: .regularExpression) != nil
        }.map { $0.index }
        
        guard !linesWithNumber.isEmpty else { return nil }
        
        for index in linesWithNumber {
            let candidates = tokenCandidates(in: rawLines[index])
            if let code = candidates.first(where: isSetCodeToken) {
                print("🧠 CardTextParser: setIdGuess source line \(index): \(rawLines[index])")
                return normalizeSetToken(code)
            }
            
            // Check adjacent lines
            for adjacent in [index - 1, index + 1] where rawLines.indices.contains(adjacent) {
                let adjTokens = tokenCandidates(in: rawLines[adjacent])
                if let code = adjTokens.first(where: isSetCodeToken) {
                    print("🧠 CardTextParser: setIdGuess source line \(adjacent): \(rawLines[adjacent])")
                    return normalizeSetToken(code)
                }
            }
        }
        
        return nil
    }

    private func tokenCandidates(in line: String) -> [String] {
        let cleaned = line
            .replacingOccurrences(of: "•", with: " ")
            .replacingOccurrences(of: "|", with: " ")
            .replacingOccurrences(of: "*", with: " ")
            .replacingOccurrences(of: "•", with: " ")
            .replacingOccurrences(of: "·", with: " ")
            .replacingOccurrences(of: "—", with: " ")
        return cleaned
            .components(separatedBy: CharacterSet.whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: CharacterSet.alphanumerics.inverted) }
            .filter { !$0.isEmpty }
    }

    private func isSetCodeToken(_ token: String) -> Bool {
        let upper = normalizeSetToken(token)
        let pattern = #"^[A-Z]{2,5}[0-9]{0,3}[A-Z]?$"#
        if upper.range(of: pattern, options: .regularExpression) != nil {
            return true
        }
        return false
    }
    
    private func normalizeSetToken(_ token: String) -> String {
        let cleaned = token.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        let letters = cleaned.unicodeScalars.filter { CharacterSet.letters.contains($0) }.count
        let total = cleaned.count
        let mostlyLetters = total > 0 && Double(letters) / Double(total) > 0.6
        
        var normalized = cleaned
        if mostlyLetters {
            normalized = normalized
                .replacingOccurrences(of: "0", with: "O")
                .replacingOccurrences(of: "1", with: "I")
        }
        
        return normalized.uppercased()
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
    
    private func extractName(from recognizedTexts: [RecognizedText]) -> (name: String?, fallbacks: [String]) {
        let cleanedLines = recognizedTexts.map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
        let upperLines = cleanedLines.map { $0.uppercased() }
        
        let abilityLineIndices = detectAbilityLines(upperLines)
        let abilityAdjacent = adjacentIndices(from: abilityLineIndices, count: cleanedLines.count)
        let damageLineIndices = detectDamageLines(cleanedLines)
        let attackAdjacent = adjacentIndices(from: damageLineIndices, count: cleanedLines.count)
        
        var candidates: [(original: String, normalized: String, score: Double, index: Int, flags: [String])] = []
        
        for (index, line) in cleanedLines.enumerated() {
            guard !line.isEmpty else { continue }
            
            let upper = upperLines[index]
            if containsStopWord(upper) { continue }
            if filterWords.contains(upper) { continue }
            
            let normalized = normalizeNameCandidate(line)
            let boundingBox = recognizedTexts[index].boundingBox
            let scoreResult = scoreCandidate(
                normalized,
                rawUpper: upper,
                index: index,
                abilityAdjacent: abilityAdjacent,
                attackAdjacent: attackAdjacent,
                boundingBox: boundingBox
            )
            
            if scoreResult.score.isFinite {
                candidates.append((line, normalized, scoreResult.score, index, scoreResult.flags))
            }
        }
        
        // Log candidates for debugging
        if !candidates.isEmpty {
            let log = candidates
                .sorted { $0.score > $1.score }
                .map {
                    "\($0.original) -> \($0.normalized) | \(String(format: "%.2f", $0.score)) | [\($0.flags.joined(separator: ","))]"
                }
                .joined(separator: " ; ")
            print("🧠 CardTextParser: nameCandidates: \(log)")
        } else {
            print("🧠 CardTextParser: nameCandidates: []")
        }
        
        let best = candidates.sorted {
            if $0.score == $1.score { return $0.index < $1.index }
            return $0.score > $1.score
        }.first
        
        let fallbackNames = detectPokemonNameFallbacks(from: cleanedLines)
        print("🧠 CardTextParser: nameGuess: \(best?.normalized ?? "nil")")
        if !fallbackNames.isEmpty {
            print("🧠 CardTextParser: nameFallbacks: \(fallbackNames)")
        }
        
        return (best?.normalized, fallbackNames)
    }
    
    private func containsStopWord(_ upperLine: String) -> Bool {
        for word in nameStopWords {
            if upperLine.contains(word.uppercased()) {
                return true
            }
        }
        return false
    }
    
    private func isNameLikeCandidate(_ candidate: String) -> Bool {
        let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3, trimmed.count <= 20 else { return false }
        
        let words = trimmed.split(separator: " ")
        if words.count > 3 { return false }
        
        let letters = trimmed.unicodeScalars.filter { CharacterSet.letters.contains($0) }.count
        let lettersAndSpaces = trimmed.unicodeScalars.filter {
            CharacterSet.letters.contains($0)
            || CharacterSet.whitespaces.contains($0)
            || $0 == "-" || $0 == "." || $0 == "'"
        }.count
        
        if letters == 0 || lettersAndSpaces == 0 { return false }
        let ratio = Double(letters) / Double(lettersAndSpaces)
        if ratio < 0.7 { return false }
        
        if trimmed.range(of: #"^\d+$"#, options: .regularExpression) != nil {
            return false
        }
        
        if trimmed.uppercased().contains("HP") {
            return false
        }
        
        if trimmed.range(of: #"\d"#, options: .regularExpression) != nil {
            return false
        }
        
        if trimmed.contains(":") || trimmed.contains(",") || trimmed.contains("*") {
            return false
        }
        
        return true
    }
    
    private func scoreCandidate(
        _ candidate: String,
        rawUpper: String,
        index: Int,
        abilityAdjacent: Set<Int>,
        attackAdjacent: Set<Int>,
        boundingBox: CGRect?
    ) -> (score: Double, flags: [String]) {
        let upper = candidate.uppercased()
        var flags: [String] = []
        
        if hardStopWords.contains(upper) { return (-.infinity, ["hardStop"]) }
        for stop in hardStopWords where rawUpper.contains(stop) {
            return (-.infinity, ["hardStop"])
        }
        
        if !isNameLikeCandidate(candidate) { return (-.infinity, ["invalid"]) }
        
        let wordCount = candidate.split(separator: " ").count
        let allowsThree = upper.contains("EX") || upper.contains(" V")
        if wordCount > 2 && !allowsThree { return (-.infinity, ["tooManyWords"]) }
        
        var score = 0.0
        let lengthScore = 1.0 - (Double(abs(candidate.count - 8)) / 20.0)
        score += max(0.0, lengthScore)
        
        if wordCount == 1 {
            score += 0.6
        } else if wordCount == 2 {
            score += 0.3
        }
        
        if abilityAdjacent.contains(index) {
            return (-.infinity, ["abilityAdjacent"])
        }
        
        if attackAdjacent.contains(index) {
            score -= 0.8
            flags.append("attackAdjacent")
        }
        
        for word in attackLikeWords {
            if upper.contains(word) {
                score -= 0.2
                flags.append("attackWord")
                break
            }
        }
        
        if let box = boundingBox {
            if box.minY < 0.30 {
                score += 0.5
                flags.append("topZone")
            } else if box.minY > 0.45 && box.minY < 0.85 {
                score -= 0.3
                flags.append("midZone")
            }
        }
        
        return (score, flags)
    }
    
    private func normalizeNameCandidate(_ line: String) -> String {
        // Remove stray punctuation and normalize spaces
        var cleaned = line
            .replacingOccurrences(of: "º", with: "")
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        cleaned = normalizeLeetspeak(cleaned)
        cleaned = cleaned.replacingOccurrences(of: "  ", with: " ")
        
        return cleaned.capitalized
    }

    private func detectAbilityLines(_ upperLines: [String]) -> Set<Int> {
        var indices: Set<Int> = []
        for (i, line) in upperLines.enumerated() {
            if isAbilityLine(line) {
                indices.insert(i)
            }
        }
        return indices
    }
    
    private func isAbilityLine(_ upperLine: String) -> Bool {
        let normalized = upperLine
            .replacingOccurrences(of: "1", with: "I")
            .replacingOccurrences(of: "L", with: "I")
            .replacingOccurrences(of: "|", with: "I")
            .components(separatedBy: CharacterSet.letters.inverted)
            .joined()
        
        let tokens = [
            "ABILITY", "ABILTY", "ABIITY", "ABIIITY",
            "HABILIDAD", "HABIIDAD"
        ]
        
        for token in tokens {
            if normalized.contains(token) {
                return true
            }
        }
        
        return false
    }
    
    private func detectDamageLines(_ lines: [String]) -> Set<Int> {
        var indices: Set<Int> = []
        for (i, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.range(of: #"^[+-]?\d{1,3}$"#, options: .regularExpression) != nil {
                indices.insert(i)
            }
        }
        return indices
    }
    
    private func adjacentIndices(from indices: Set<Int>, count: Int) -> Set<Int> {
        var result: Set<Int> = []
        for i in indices {
            if i > 0 { result.insert(i - 1) }
            if i + 1 < count { result.insert(i + 1) }
        }
        return result
    }
    
    private func detectPokemonNameFallbacks(from lines: [String]) -> [String] {
        var results: [String] = []
        var unique: Set<String> = []
        
        for line in lines {
            let normalizedLine = normalizeLeetspeak(line)
            let lettersOnly = normalizedLine
                .components(separatedBy: CharacterSet.letters.inverted)
                .filter { !$0.isEmpty }
                .joined(separator: " ")
                .uppercased()
            
            if pokemonNameSet.contains(lettersOnly), !unique.contains(lettersOnly) {
                unique.insert(lettersOnly)
                results.append(lettersOnly.capitalized)
                continue
            }
            
            let tokens = normalizedLine
                .components(separatedBy: CharacterSet.letters.inverted)
                .filter { !$0.isEmpty }
            
            for token in tokens {
                let upper = token.uppercased()
                if pokemonNameSet.contains(upper), !unique.contains(upper) {
                    unique.insert(upper)
                    results.append(token.capitalized)
                }
            }
        }
        
        return Array(results.prefix(3))
    }
    
    private func normalizeLeetspeak(_ text: String) -> String {
        let chars = Array(text)
        var output: [Character] = []
        
        for i in chars.indices {
            let current = chars[i]
            let prev = i > chars.startIndex ? chars[chars.index(before: i)] : nil
            let next = i < chars.index(before: chars.endIndex) ? chars[chars.index(after: i)] : nil
            
            if current == "1",
               let p = prev, let n = next,
               isLetter(p), isLetter(n) {
                output.append("l")
                continue
            }
            
            if current == "0",
               let p = prev, let n = next,
               isLetter(p), isLetter(n) {
                output.append("o")
                continue
            }
            
            output.append(current)
        }
        
        return String(output)
    }
    
    private func isLetter(_ character: Character) -> Bool {
        character.unicodeScalars.allSatisfy { CharacterSet.letters.contains($0) }
    }
}
