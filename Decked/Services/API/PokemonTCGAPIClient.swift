//
//  PokemonTCGAPIClient.swift
//  Decked
//
//  Real API client for Pokémon TCG API v2
//

import Foundation

// MARK: - API Client Protocol
protocol PokemonTCGAPIClientProtocol {
    func searchCards(hint: ParsedCardHint) async throws -> [CardMatch]
    func searchCardsByName(_ name: String) async throws -> [CardMatch]
    func getCard(id: String) async throws -> CardMatch?
}

// MARK: - Pokémon TCG API Client
final class PokemonTCGAPIClient: PokemonTCGAPIClientProtocol {
    
    // MARK: - Properties
    
    private let baseURL = "https://api.pokemontcg.io/v2"
    private let session: URLSession
    private let apiKey: String?
    
    // MARK: - Initialization
    
    init(apiKey: String? = nil, session: URLSession = .shared) {
        self.apiKey = apiKey ?? Bundle.main.object(forInfoDictionaryKey: "PokemonTCGAPIKey") as? String
        self.session = session
        
        if self.apiKey != nil {
            print("🔑 PokemonTCGAPIClient: API key configured")
        } else {
            print("⚠️ PokemonTCGAPIClient: No API key, using public access")
        }
    }
    
    // MARK: - Public Methods
    
    func searchCards(hint: ParsedCardHint) async throws -> [CardMatch] {
        print("🔍 PokemonTCGAPIClient: Searching with hint: \(hint)")
        
        // Strategy 1: Try with number + name if both available
        if let number = hint.numberGuess, let name = hint.nameGuess {
            let escapedName = name.replacingOccurrences(of: "\"", with: "\\\"")
            let query = "number:\"\(number)\" name:\"\(escapedName)\""
            
            do {
                let results = try await searchCards(query: query)
                if !results.isEmpty {
                    print("✅ Found \(results.count) cards with number + name")
                    return results
                }
            } catch APIError.httpError(404) {
                print("⚠️ No results with number + name, trying number only...")
            } catch {
                throw error
            }
        }
        
        // Strategy 2: Try with number only (more reliable than OCR name)
        if let number = hint.numberGuess {
            let query = "number:\"\(number)\""
            
            do {
                let results = try await searchCards(query: query)
                if !results.isEmpty {
                    print("✅ Found \(results.count) cards with number only")
                    return results
                }
            } catch APIError.httpError(404) {
                print("⚠️ No results with number, trying name...")
            } catch {
                throw error
            }
        }
        
        // Strategy 3: Try with name only using wildcard
        if let name = hint.nameGuess, name.count >= 3 {
            let escapedName = name.replacingOccurrences(of: "\"", with: "\\\"")
            let query = "name:\"\(escapedName)*\""
            
            do {
                let results = try await searchCards(query: query)
                if !results.isEmpty {
                    print("✅ Found \(results.count) cards with name wildcard")
                    return results
                }
            } catch APIError.httpError(404) {
                print("⚠️ No results with any strategy")
            } catch {
                throw error
            }
        }
        
        // No results found with any strategy
        print("❌ No cards found matching criteria")
        return []
    }
    
    func searchCardsByName(_ name: String) async throws -> [CardMatch] {
        let escapedName = name.replacingOccurrences(of: "\"", with: "\\\"")
        let query = "name:\"\(escapedName)\""
        return try await searchCards(query: query)
    }
    
    func getCard(id: String) async throws -> CardMatch? {
        guard let url = URL(string: "\(baseURL)/cards/\(id)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        addHeaders(to: &request)
        
        print("🌐 PokemonTCGAPIClient: GET \(url)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("📡 PokemonTCGAPIClient: Response status: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        let singleResponse = try JSONDecoder().decode(SingleCardResponse.self, from: data)
        return singleResponse.data.toCardMatch()
    }
    
    // MARK: - Private Methods
    
    private func searchCards(query: String) async throws -> [CardMatch] {
        guard var components = URLComponents(string: "\(baseURL)/cards") else {
            throw APIError.invalidURL
        }
        
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "pageSize", value: "20")
        ]
        
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        addHeaders(to: &request)
        
        print("🌐 PokemonTCGAPIClient: GET \(url)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("📡 PokemonTCGAPIClient: Response status: \(httpResponse.statusCode)")
        
        // Handle 404 as empty results instead of error
        if httpResponse.statusCode == 404 {
            print("⚠️ PokemonTCGAPIClient: 404 - No cards found")
            throw APIError.httpError(404)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        let searchResponse = try JSONDecoder().decode(SearchCardsResponse.self, from: data)
        
        print("✅ PokemonTCGAPIClient: Found \(searchResponse.data.count) cards")
        
        return searchResponse.data.map { $0.toCardMatch() }
    }
    
    private func addHeaders(to request: inout URLRequest) {
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let apiKey = apiKey {
            request.setValue(apiKey, forHTTPHeaderField: "X-Api-Key")
        }
    }
}

// MARK: - API DTOs

struct SearchCardsResponse: Decodable {
    let data: [CardDTO]
    let page: Int?
    let pageSize: Int?
    let count: Int?
    let totalCount: Int?
}

struct SingleCardResponse: Decodable {
    let data: CardDTO
}

struct CardDTO: Decodable {
    let id: String
    let name: String
    let number: String
    let rarity: String?
    let images: CardImagesDTO
    let set: CardSetDTO
    
    func toCardMatch() -> CardMatch {
        CardMatch(
            id: id,
            card: Card(
                id: id,
                name: name,
                setId: set.id,
                setName: set.name,
                number: number,
                rarity: CardRarity.from(rarity ?? "Common"),
                imageURL: URL(string: images.small),
                imageURLHighRes: URL(string: images.large),
                artist: nil,
                supertype: nil,
                subtypes: nil,
                hp: nil,
                types: nil,
                nationalPokedexNumber: nil,
                marketPrice: nil,
                lowPrice: nil,
                highPrice: nil,
                setSeries: nil,
                setReleaseDate: nil,
                setTotalCards: nil
            ),
            confidence: 1.0, // From API, assume 100% confidence
            matchedFields: ["name", "number"] // API returns exact matches
        )
    }
}

struct CardImagesDTO: Decodable {
    let small: String
    let large: String
}

struct CardSetDTO: Decodable {
    let id: String
    let name: String
}

// MARK: - API Errors

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
    case noResults
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .noResults:
            return "No cards found matching your search"
        }
    }
}
