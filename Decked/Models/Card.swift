//
//  Card.swift
//  Decked
//
//  Core card models for Pokémon TCG collection
//

import Foundation
import SwiftUI

// MARK: - Card Model
/// Represents a Pokémon TCG card from the API/database
struct Card: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let setId: String
    let setName: String
    let number: String
    let rarity: CardRarity
    let imageURL: URL?
    let imageURLHighRes: URL?
    let artist: String?
    let supertype: String? // Pokémon, Trainer, Energy
    let subtypes: [String]?
    let hp: String?
    let types: [String]?
    let nationalPokedexNumber: Int?
    
    // Market data (optional)
    let marketPrice: Double?
    let lowPrice: Double?
    let highPrice: Double?
    
    // Set info
    let setSeries: String?
    let setReleaseDate: String?
    let setTotalCards: Int?
    
    // Computed property for backward compatibility
    var imageLargeURL: URL? {
        imageURLHighRes
    }
    
    // CodingKeys to exclude computed property from Codable
    enum CodingKeys: String, CodingKey {
        case id, name, setId, setName, number, rarity, imageURL, imageURLHighRes
        case artist, supertype, subtypes, hp, types, nationalPokedexNumber
        case marketPrice, lowPrice, highPrice
        case setSeries, setReleaseDate, setTotalCards
    }
}

// MARK: - Card Rarity
enum CardRarity: String, Codable, CaseIterable, Hashable {
    case common = "Common"
    case uncommon = "Uncommon"
    case rare = "Rare"
    case holo = "Rare Holo"
    case ultraRare = "Ultra Rare"
    case secretRare = "Secret Rare"
    case specialArt = "Special Art Rare"
    case illustrationRare = "Illustration Rare"
    case unknown = "Unknown"
    
    /// Aliases for parsing different formats
    static func from(_ string: String) -> CardRarity {
        let normalized = string.uppercased().trimmingCharacters(in: .whitespaces)
        
        // Direct matches
        for rarity in CardRarity.allCases {
            if rarity.rawValue.uppercased() == normalized {
                return rarity
            }
        }
        
        // Alias mapping
        let aliases: [String: CardRarity] = [
            "C": .common,
            "U": .uncommon,
            "R": .rare,
            "RR": .rare,
            "RH": .holo,
            "HOLO": .holo,
            "HOLO RARE": .holo,
            "UR": .ultraRare,
            "SR": .secretRare,
            "SAR": .specialArt,
            "SIR": .specialArt,
            "SPECIAL ILLUSTRATION RARE": .specialArt,
            "IR": .illustrationRare,
            "AR": .illustrationRare,
            "ART RARE": .illustrationRare,
            "HYPER RARE": .secretRare,
            "HR": .secretRare,
            "PROMO": .rare,
            "RARE ULTRA": .ultraRare,
            "DOUBLE RARE": .rare,
            "TRAINER GALLERY": .illustrationRare
        ]
        
        if let matched = aliases[normalized] {
            return matched
        }
        
        // Partial matching
        if normalized.contains("SECRET") { return .secretRare }
        if normalized.contains("ULTRA") { return .ultraRare }
        if normalized.contains("ILLUSTRATION") { return .illustrationRare }
        if normalized.contains("SPECIAL") { return .specialArt }
        if normalized.contains("HOLO") { return .holo }
        if normalized.contains("RARE") { return .rare }
        if normalized.contains("UNCOMMON") { return .uncommon }
        if normalized.contains("COMMON") { return .common }
        
        return .unknown
    }
    
    var displayName: String {
        rawValue
    }
    
    var shortName: String {
        switch self {
        case .common: return "C"
        case .uncommon: return "U"
        case .rare: return "R"
        case .holo: return "RH"
        case .ultraRare: return "UR"
        case .secretRare: return "SR"
        case .specialArt: return "SAR"
        case .illustrationRare: return "IR"
        case .unknown: return "?"
        }
    }
}

// MARK: - Card Language
enum CardLanguage: String, Codable, CaseIterable, Hashable {
    case english = "EN"
    case spanish = "ES"
    case japanese = "JP"
    case korean = "KR"
    case french = "FR"
    case german = "DE"
    case italian = "IT"
    case portuguese = "PT"
    case chinese = "CN"
    
    var code: String {
        return rawValue
    }
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Español"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .italian: return "Italiano"
        case .portuguese: return "Português"
        case .chinese: return "中文"
        }
    }
    
    var flag: String {
        switch self {
        case .english: return "🇺🇸"
        case .spanish: return "🇪🇸"
        case .japanese: return "🇯🇵"
        case .korean: return "🇰🇷"
        case .french: return "🇫🇷"
        case .german: return "🇩🇪"
        case .italian: return "🇮🇹"
        case .portuguese: return "🇧🇷"
        case .chinese: return "🇨🇳"
        }
    }
}

// MARK: - Card Condition
enum CardCondition: String, Codable, CaseIterable, Hashable {
    case nearMint = "NM"
    case lightlyPlayed = "LP"
    case moderatelyPlayed = "MP"
    case heavilyPlayed = "HP"
    case damaged = "DMG"
    
    var displayName: String {
        switch self {
        case .nearMint: return "Near Mint"
        case .lightlyPlayed: return "Lightly Played"
        case .moderatelyPlayed: return "Moderately Played"
        case .heavilyPlayed: return "Heavily Played"
        case .damaged: return "Damaged"
        }
    }
    
    var shortCode: String {
        rawValue
    }
    
    var shortName: String {
        rawValue
    }
    
    var color: Color {
        switch self {
        case .nearMint: return .deckSuccess
        case .lightlyPlayed: return .deckAccent
        case .moderatelyPlayed: return .deckWarning
        case .heavilyPlayed: return .deckError
        case .damaged: return .deckTextMuted
        }
    }
    
    var conditionMultiplier: Double {
        switch self {
        case .nearMint: return 1.0
        case .lightlyPlayed: return 0.85
        case .moderatelyPlayed: return 0.70
        case .heavilyPlayed: return 0.50
        case .damaged: return 0.25
        }
    }
}

// MARK: - Collection Card
/// A card in the user's collection with additional metadata
struct CollectionCard: Identifiable, Codable, Hashable {
    let id: UUID
    let card: Card
    let language: CardLanguage
    let condition: CardCondition
    let isFoil: Bool
    let quantity: Int
    let pricePaid: Double?
    let dateAdded: Date
    let binderId: UUID?
    let notes: String?
    
    init(
        id: UUID = UUID(),
        card: Card,
        language: CardLanguage = .english,
        condition: CardCondition = .nearMint,
        isFoil: Bool = false,
        quantity: Int = 1,
        pricePaid: Double? = nil,
        dateAdded: Date = Date(),
        binderId: UUID? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.card = card
        self.language = language
        self.condition = condition
        self.isFoil = isFoil
        self.quantity = quantity
        self.pricePaid = pricePaid
        self.dateAdded = dateAdded
        self.binderId = binderId
        self.notes = notes
    }
    
    var estimatedValue: Double? {
        guard let marketPrice = card.marketPrice else { return nil }
        return marketPrice * condition.conditionMultiplier * Double(quantity)
    }
}

// MARK: - Binder
/// A digital binder/folder for organizing cards
struct Binder: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var description: String?
    var coverImageURL: URL?
    var accentColorHex: String
    var cardIds: [UUID]
    let createdAt: Date
    var updatedAt: Date
    var isPublic: Bool
    var sortOrder: Int
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        coverImageURL: URL? = nil,
        accentColorHex: String = "38BDF8",
        cardIds: [UUID] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isPublic: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.coverImageURL = coverImageURL
        self.accentColorHex = accentColorHex
        self.cardIds = cardIds
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPublic = isPublic
        self.sortOrder = sortOrder
    }
    
    var cardCount: Int {
        cardIds.count
    }
}

// MARK: - Card Match (API Response)
/// Represents a potential match from the identification API
struct CardMatch: Identifiable, Hashable {
    let id: String
    let card: Card
    let confidence: Double // 0.0 to 1.0
    let matchedFields: [String] // Which fields matched
    
    var confidencePercentage: Int {
        Int(confidence * 100)
    }
}
