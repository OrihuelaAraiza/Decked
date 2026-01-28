//
//  CardAPIClient.swift
//  Decked
//
//  API client for card identification (mock implementation)
//  Designed for easy migration to Pokémon TCG API v2
//

import Foundation

// MARK: - Card API Client Protocol
protocol CardAPIClientProtocol {
    func searchCards(hint: ParsedCardHint) async throws -> [CardMatch]
    func getCard(id: String) async throws -> Card?
    func searchByName(_ name: String) async throws -> [Card]
    func searchBySet(setId: String) async throws -> [Card]
}

// MARK: - Card API Client
final class CardAPIClient: CardAPIClientProtocol {
    
    // MARK: - Properties
    
    /// Base URL for Pokémon TCG API (for future implementation)
    private let baseURL = "https://api.pokemontcg.io/v2"
    
    /// API Key (optional for higher rate limits)
    private var apiKey: String?
    
    /// URLSession for network requests
    private let session: URLSession
    
    /// Use mock data instead of real API
    private let useMockData: Bool
    
    // MARK: - Initialization
    
    init(apiKey: String? = nil, useMockData: Bool = true) {
        self.apiKey = apiKey
        self.useMockData = useMockData
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        
        if let apiKey = apiKey {
            config.httpAdditionalHeaders = ["X-Api-Key": apiKey]
        }
        
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Public Methods
    
    func searchCards(hint: ParsedCardHint) async throws -> [CardMatch] {
        // For MVP, use mock data
        if useMockData {
            return searchMockCards(hint: hint)
        }
        
        // Future: Real API implementation
        // let query = buildSearchQuery(from: hint)
        // let url = URL(string: "\(baseURL)/cards?\(query)")!
        // let (data, _) = try await session.data(from: url)
        // return try JSONDecoder().decode([CardMatch].self, from: data)
        
        return []
    }
    
    func getCard(id: String) async throws -> Card? {
        if useMockData {
            return MockCardData.allCards.first { $0.id == id }
        }
        
        // Future: Real API implementation
        return nil
    }
    
    func searchByName(_ name: String) async throws -> [Card] {
        if useMockData {
            let normalizedName = name.lowercased()
            return MockCardData.allCards.filter {
                $0.name.lowercased().contains(normalizedName)
            }
        }
        
        return []
    }
    
    func searchBySet(setId: String) async throws -> [Card] {
        if useMockData {
            return MockCardData.allCards.filter { $0.setId == setId }
        }
        
        return []
    }
    
    // MARK: - Private Methods
    
    private func searchMockCards(hint: ParsedCardHint) -> [CardMatch] {
        var matches: [CardMatch] = []
        
        for card in MockCardData.allCards {
            var confidence: Double = 0.0
            var matchedFields: [String] = []
            
            // Match by number (highest priority)
            if let numberGuess = hint.numberGuess,
               card.number.contains(numberGuess) || numberGuess.contains(card.number) {
                confidence += 0.5
                matchedFields.append("number")
            }
            
            // Match by name
            if let nameGuess = hint.nameGuess {
                let normalizedGuess = nameGuess.lowercased()
                let normalizedCardName = card.name.lowercased()
                
                if normalizedCardName.contains(normalizedGuess) || normalizedGuess.contains(normalizedCardName) {
                    confidence += 0.3
                    matchedFields.append("name")
                } else {
                    // Fuzzy match - check for common characters
                    let guessSet = Set(normalizedGuess)
                    let cardSet = Set(normalizedCardName)
                    let intersection = guessSet.intersection(cardSet)
                    let similarity = Double(intersection.count) / Double(max(guessSet.count, cardSet.count))
                    if similarity > 0.6 {
                        confidence += 0.15
                        matchedFields.append("name_fuzzy")
                    }
                }
            }
            
            // Match by rarity
            if let rarityGuess = hint.rarityGuess, card.rarity == rarityGuess {
                confidence += 0.1
                matchedFields.append("rarity")
            }
            
            // Match by HP
            if let hpGuess = hint.hp, card.hp == hpGuess {
                confidence += 0.1
                matchedFields.append("hp")
            }
            
            // Only include if we have some confidence
            if confidence > 0.2 {
                matches.append(CardMatch(
                    id: card.id,
                    card: card,
                    confidence: min(confidence, 1.0),
                    matchedFields: matchedFields
                ))
            }
        }
        
        // Sort by confidence descending
        return matches.sorted { $0.confidence > $1.confidence }
    }
    
    /// Builds query string for Pokémon TCG API
    private func buildSearchQuery(from hint: ParsedCardHint) -> String {
        var queryParts: [String] = []
        
        if let name = hint.nameGuess {
            queryParts.append("name:\"\(name)\"")
        }
        
        if let number = hint.numberGuess {
            queryParts.append("number:\(number)")
        }
        
        if let rarity = hint.rarityGuess {
            queryParts.append("rarity:\"\(rarity.rawValue)\"")
        }
        
        let query = queryParts.joined(separator: " ")
        return "q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
    }
}

// MARK: - Mock Card Data
struct MockCardData {
    
    static let allCards: [Card] = [
        // Scarlet & Violet Base Set
        Card(
            id: "sv1-001",
            name: "Sprigatito",
            setId: "sv1",
            setName: "Scarlet & Violet",
            number: "001",
            rarity: .common,
            imageURL: URL(string: "https://images.pokemontcg.io/sv1/1.png"),
            imageURLHighRes: URL(string: "https://images.pokemontcg.io/sv1/1_hires.png"),
            artist: "Akira Komayama",
            supertype: "Pokémon",
            subtypes: ["Basic"],
            hp: "70",
            types: ["Grass"],
            nationalPokedexNumber: 906,
            marketPrice: 0.25,
            lowPrice: 0.10,
            highPrice: 0.50,
            setSeries: "Scarlet & Violet",
            setReleaseDate: "2023/03/31",
            setTotalCards: 198
        ),
        Card(
            id: "sv1-058",
            name: "Pikachu",
            setId: "sv1",
            setName: "Scarlet & Violet",
            number: "058",
            rarity: .common,
            imageURL: URL(string: "https://images.pokemontcg.io/sv1/58.png"),
            imageURLHighRes: URL(string: "https://images.pokemontcg.io/sv1/58_hires.png"),
            artist: "Mitsuhiro Arita",
            supertype: "Pokémon",
            subtypes: ["Basic"],
            hp: "60",
            types: ["Lightning"],
            nationalPokedexNumber: 25,
            marketPrice: 0.50,
            lowPrice: 0.25,
            highPrice: 1.00,
            setSeries: "Scarlet & Violet",
            setReleaseDate: "2023/03/31",
            setTotalCards: 198
        ),
        Card(
            id: "sv1-195",
            name: "Miraidon ex",
            setId: "sv1",
            setName: "Scarlet & Violet",
            number: "195",
            rarity: .ultraRare,
            imageURL: URL(string: "https://images.pokemontcg.io/sv1/195.png"),
            imageURLHighRes: URL(string: "https://images.pokemontcg.io/sv1/195_hires.png"),
            artist: "5ban Graphics",
            supertype: "Pokémon",
            subtypes: ["Basic", "ex"],
            hp: "220",
            types: ["Lightning"],
            nationalPokedexNumber: 1008,
            marketPrice: 18.50,
            lowPrice: 15.00,
            highPrice: 25.00,
            setSeries: "Scarlet & Violet",
            setReleaseDate: "2023/03/31",
            setTotalCards: 198
        ),
        Card(
            id: "sv1-211",
            name: "Miraidon ex",
            setId: "sv1",
            setName: "Scarlet & Violet",
            number: "211",
            rarity: .specialArt,
            imageURL: URL(string: "https://images.pokemontcg.io/sv1/211.png"),
            imageURLHighRes: URL(string: "https://images.pokemontcg.io/sv1/211_hires.png"),
            artist: "Takumi Wada",
            supertype: "Pokémon",
            subtypes: ["Basic", "ex"],
            hp: "220",
            types: ["Lightning"],
            nationalPokedexNumber: 1008,
            marketPrice: 85.00,
            lowPrice: 70.00,
            highPrice: 110.00,
            setSeries: "Scarlet & Violet",
            setReleaseDate: "2023/03/31",
            setTotalCards: 198
        ),
        
        // Paldea Evolved
        Card(
            id: "sv2-107",
            name: "Charizard ex",
            setId: "sv2",
            setName: "Paldea Evolved",
            number: "107",
            rarity: .rare,
            imageURL: URL(string: "https://images.pokemontcg.io/sv2/107.png"),
            imageURLHighRes: URL(string: "https://images.pokemontcg.io/sv2/107_hires.png"),
            artist: "5ban Graphics",
            supertype: "Pokémon",
            subtypes: ["Stage 2", "ex"],
            hp: "330",
            types: ["Fire"],
            nationalPokedexNumber: 6,
            marketPrice: 8.50,
            lowPrice: 6.00,
            highPrice: 12.00,
            setSeries: "Scarlet & Violet",
            setReleaseDate: "2023/06/09",
            setTotalCards: 193
        ),
        Card(
            id: "sv2-223",
            name: "Charizard ex",
            setId: "sv2",
            setName: "Paldea Evolved",
            number: "223",
            rarity: .specialArt,
            imageURL: URL(string: "https://images.pokemontcg.io/sv2/223.png"),
            imageURLHighRes: URL(string: "https://images.pokemontcg.io/sv2/223_hires.png"),
            artist: "Mitsuhiro Arita",
            supertype: "Pokémon",
            subtypes: ["Stage 2", "ex"],
            hp: "330",
            types: ["Fire"],
            nationalPokedexNumber: 6,
            marketPrice: 150.00,
            lowPrice: 120.00,
            highPrice: 200.00,
            setSeries: "Scarlet & Violet",
            setReleaseDate: "2023/06/09",
            setTotalCards: 193
        ),
        
        // Obsidian Flames
        Card(
            id: "sv3-130",
            name: "Charizard ex",
            setId: "sv3",
            setName: "Obsidian Flames",
            number: "130",
            rarity: .rare,
            imageURL: URL(string: "https://images.pokemontcg.io/sv3/130.png"),
            imageURLHighRes: URL(string: "https://images.pokemontcg.io/sv3/130_hires.png"),
            artist: "5ban Graphics",
            supertype: "Pokémon",
            subtypes: ["Stage 2", "ex", "Tera"],
            hp: "330",
            types: ["Darkness"],
            nationalPokedexNumber: 6,
            marketPrice: 45.00,
            lowPrice: 35.00,
            highPrice: 60.00,
            setSeries: "Scarlet & Violet",
            setReleaseDate: "2023/08/11",
            setTotalCards: 197
        ),
        Card(
            id: "sv3-215",
            name: "Charizard ex",
            setId: "sv3",
            setName: "Obsidian Flames",
            number: "215",
            rarity: .specialArt,
            imageURL: URL(string: "https://images.pokemontcg.io/sv3/215.png"),
            imageURLHighRes: URL(string: "https://images.pokemontcg.io/sv3/215_hires.png"),
            artist: "kantaro",
            supertype: "Pokémon",
            subtypes: ["Stage 2", "ex", "Tera"],
            hp: "330",
            types: ["Darkness"],
            nationalPokedexNumber: 6,
            marketPrice: 250.00,
            lowPrice: 200.00,
            highPrice: 320.00,
            setSeries: "Scarlet & Violet",
            setReleaseDate: "2023/08/11",
            setTotalCards: 197
        ),
        
        // 151
        Card(
            id: "sv3pt5-025",
            name: "Pikachu",
            setId: "sv3pt5",
            setName: "151",
            number: "025",
            rarity: .common,
            imageURL: URL(string: "https://images.pokemontcg.io/sv3pt5/25.png"),
            imageURLHighRes: URL(string: "https://images.pokemontcg.io/sv3pt5/25_hires.png"),
            artist: "Mitsuhiro Arita",
            supertype: "Pokémon",
            subtypes: ["Basic"],
            hp: "60",
            types: ["Lightning"],
            nationalPokedexNumber: 25,
            marketPrice: 1.50,
            lowPrice: 1.00,
            highPrice: 2.50,
            setSeries: "Scarlet & Violet",
            setReleaseDate: "2023/09/22",
            setTotalCards: 165
        ),
        Card(
            id: "sv3pt5-172",
            name: "Pikachu ex",
            setId: "sv3pt5",
            setName: "151",
            number: "172",
            rarity: .ultraRare,
            imageURL: URL(string: "https://images.pokemontcg.io/sv3pt5/172.png"),
            imageURLHighRes: URL(string: "https://images.pokemontcg.io/sv3pt5/172_hires.png"),
            artist: "PLANETA Mochizuki",
            supertype: "Pokémon",
            subtypes: ["Basic", "ex"],
            hp: "200",
            types: ["Lightning"],
            nationalPokedexNumber: 25,
            marketPrice: 35.00,
            lowPrice: 28.00,
            highPrice: 45.00,
            setSeries: "Scarlet & Violet",
            setReleaseDate: "2023/09/22",
            setTotalCards: 165
        ),
        Card(
            id: "sv3pt5-199",
            name: "Alakazam ex",
            setId: "sv3pt5",
            setName: "151",
            number: "199",
            rarity: .specialArt,
            imageURL: URL(string: "https://images.pokemontcg.io/sv3pt5/199.png"),
            imageURLHighRes: URL(string: "https://images.pokemontcg.io/sv3pt5/199_hires.png"),
            artist: "Anesaki Dynamic",
            supertype: "Pokémon",
            subtypes: ["Stage 2", "ex"],
            hp: "310",
            types: ["Psychic"],
            nationalPokedexNumber: 65,
            marketPrice: 65.00,
            lowPrice: 55.00,
            highPrice: 80.00,
            setSeries: "Scarlet & Violet",
            setReleaseDate: "2023/09/22",
            setTotalCards: 165
        ),
        
        // Temporal Forces
        Card(
            id: "sv5-123",
            name: "Iron Thorns ex",
            setId: "sv5",
            setName: "Temporal Forces",
            number: "123",
            rarity: .rare,
            imageURL: URL(string: "https://images.pokemontcg.io/sv5/123.png"),
            imageURLHighRes: URL(string: "https://images.pokemontcg.io/sv5/123_hires.png"),
            artist: "5ban Graphics",
            supertype: "Pokémon",
            subtypes: ["Basic", "ex"],
            hp: "230",
            types: ["Lightning"],
            nationalPokedexNumber: nil,
            marketPrice: 4.50,
            lowPrice: 3.00,
            highPrice: 6.00,
            setSeries: "Scarlet & Violet",
            setReleaseDate: "2024/03/22",
            setTotalCards: 162
        ),
        
        // Some classic cards
        Card(
            id: "base1-4",
            name: "Charizard",
            setId: "base1",
            setName: "Base Set",
            number: "4",
            rarity: .holo,
            imageURL: URL(string: "https://images.pokemontcg.io/base1/4.png"),
            imageURLHighRes: URL(string: "https://images.pokemontcg.io/base1/4_hires.png"),
            artist: "Mitsuhiro Arita",
            supertype: "Pokémon",
            subtypes: ["Stage 2"],
            hp: "120",
            types: ["Fire"],
            nationalPokedexNumber: 6,
            marketPrice: 350.00,
            lowPrice: 200.00,
            highPrice: 600.00,
            setSeries: "Base",
            setReleaseDate: "1999/01/09",
            setTotalCards: 102
        ),
        Card(
            id: "base1-58",
            name: "Pikachu",
            setId: "base1",
            setName: "Base Set",
            number: "58",
            rarity: .common,
            imageURL: URL(string: "https://images.pokemontcg.io/base1/58.png"),
            imageURLHighRes: URL(string: "https://images.pokemontcg.io/base1/58_hires.png"),
            artist: "Mitsuhiro Arita",
            supertype: "Pokémon",
            subtypes: ["Basic"],
            hp: "40",
            types: ["Lightning"],
            nationalPokedexNumber: 25,
            marketPrice: 15.00,
            lowPrice: 8.00,
            highPrice: 25.00,
            setSeries: "Base",
            setReleaseDate: "1999/01/09",
            setTotalCards: 102
        ),
        
        // Umbreon VMAX (Alt Art) - Crown Zenith
        Card(
            id: "swsh12pt5gg-GG53",
            name: "Umbreon VMAX",
            setId: "swsh12pt5gg",
            setName: "Crown Zenith Galarian Gallery",
            number: "GG53",
            rarity: .secretRare,
            imageURL: URL(string: "https://images.pokemontcg.io/swsh12pt5gg/GG53.png"),
            imageURLHighRes: URL(string: "https://images.pokemontcg.io/swsh12pt5gg/GG53_hires.png"),
            artist: "HYOGONOSUKE",
            supertype: "Pokémon",
            subtypes: ["VMAX"],
            hp: "320",
            types: ["Darkness"],
            nationalPokedexNumber: 197,
            marketPrice: 95.00,
            lowPrice: 80.00,
            highPrice: 120.00,
            setSeries: "Sword & Shield",
            setReleaseDate: "2023/01/20",
            setTotalCards: 70
        ),
        
        // Moonbreon
        Card(
            id: "swsh7-215",
            name: "Umbreon VMAX",
            setId: "swsh7",
            setName: "Evolving Skies",
            number: "215",
            rarity: .secretRare,
            imageURL: URL(string: "https://images.pokemontcg.io/swsh7/215.png"),
            imageURLHighRes: URL(string: "https://images.pokemontcg.io/swsh7/215_hires.png"),
            artist: "KIYOTAKA OSHIYAMA",
            supertype: "Pokémon",
            subtypes: ["VMAX"],
            hp: "320",
            types: ["Darkness"],
            nationalPokedexNumber: 197,
            marketPrice: 450.00,
            lowPrice: 380.00,
            highPrice: 550.00,
            setSeries: "Sword & Shield",
            setReleaseDate: "2021/08/27",
            setTotalCards: 237
        )
    ]
}

// MARK: - API Errors
enum APIError: LocalizedError {
    case invalidURL
    case networkError(String)
    case decodingError(String)
    case notFound
    case rateLimited
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .networkError(let message):
            return "Network error: \(message)"
        case .decodingError(let message):
            return "Failed to decode response: \(message)"
        case .notFound:
            return "Card not found"
        case .rateLimited:
            return "API rate limit exceeded. Please try again later."
        }
    }
}
