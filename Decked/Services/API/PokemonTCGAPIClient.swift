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
    func searchCardsWithAttempts(hint: ParsedCardHint) async throws -> CardSearchResult
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
        let plistKey = Bundle.main.object(forInfoDictionaryKey: "PokemonTCGAPIKey") as? String
        let resolved = (apiKey ?? plistKey)?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.apiKey = (resolved?.isEmpty == true) ? nil : resolved
        self.session = session
        
        if self.apiKey != nil {
            print("🔑 PokemonTCGAPIClient: API key configured")
        } else {
            print("⚠️ PokemonTCGAPIClient: No API key, using public access")
        }
    }
    
    // MARK: - Public Methods
    
    func searchCards(hint: ParsedCardHint) async throws -> [CardMatch] {
        let result = try await searchCardsWithAttempts(hint: hint)
        return result.matches
    }
    
    func searchCardsWithAttempts(hint: ParsedCardHint) async throws -> CardSearchResult {
        print("🔍 PokemonTCGAPIClient: Searching with hint: \(hint)")
        
        let strategies = CardSearchQueryBuilder.strategies(from: hint)
        print("🔎 PokemonTCGAPIClient: queries: \(strategies.map { $0.query })")
        var attempted: [String] = []
        var lastServerError: Error?
        var lastNetworkError: Error?
        var hadNonNetworkResponse = false
        var hadAny200 = false
        var hadAny404or400 = false
        var warning: String? = apiKey == nil ? "Missing API key. Set PokemonTCGAPIKey in Info.plist to enable API results." : nil
        
        for strategy in strategies {
            attempted.append(strategy.query)
            do {
                let attempt = try await runQuery(query: strategy.query, pageSize: 20)
                hadNonNetworkResponse = true
                if attempt.statusCode == 200 { hadAny200 = true }
                if attempt.statusCode == 400 || attempt.statusCode == 404 { hadAny404or400 = true }
                print("📡 PokemonTCGAPIClient: status \(attempt.statusCode) for query: \(strategy.query)")
                print("📡 PokemonTCGAPIClient: count \(attempt.matches.count) for query: \(strategy.query)")
                
                if attempt.statusCode == 200 && !attempt.matches.isEmpty {
                    print("✅ Found \(attempt.matches.count) cards with strategy: \(strategy.label)")
                    print("🏆 PokemonTCGAPIClient: winning query: \(strategy.query)")
                    return CardSearchResult(matches: attempt.matches, attemptedQueries: attempted, warning: warning)
                }
                
                // Continue on 200 empty or 400/404
                print("⚠️ PokemonTCGAPIClient: no results for query: \(strategy.query)")
            } catch APIError.httpError(let code) {
                hadNonNetworkResponse = true
                if (500...599).contains(code) {
                    lastServerError = APIError.httpError(code)
                    print("⚠️ PokemonTCGAPIClient: server error \(code) for query: \(strategy.query)")
                } else {
                    print("⚠️ PokemonTCGAPIClient: http error \(code) for query: \(strategy.query)")
                }
                continue
            } catch {
                lastNetworkError = error
                print("⚠️ PokemonTCGAPIClient: network/error for query: \(strategy.query) -> \(error)")
                continue
            }
        }
        
        if let lastServerError = lastServerError {
            throw lastServerError
        }
        if let lastNetworkError = lastNetworkError, !hadNonNetworkResponse {
            throw lastNetworkError
        }
        if warning == nil, apiKey != nil, hadAny404or400, !hadAny200 {
            warning = "API returned 404 for all queries. Verify your API key or service status."
        }
        
        print("❌ No cards found matching criteria after all strategies")
        return CardSearchResult(matches: [], attemptedQueries: attempted, warning: warning)
    }
    
    func searchCardsByName(_ name: String) async throws -> [CardMatch] {
        let cleaned = CardSearchQueryBuilder.cleanName(name)
        let query = "name:\"\(cleaned)\""
        let attempt = try await runQuery(query: query, pageSize: 20)
        return attempt.matches
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
    
    private func runQuery(query: String, pageSize: Int) async throws -> QueryAttemptResult {
        print("🔎 PokemonTCGAPIClient: q (raw): \(query)")
        guard let url = makeCardsURL(q: query, pageSize: pageSize) else {
            throw APIError.invalidURL
        }
        print("🌐 PokemonTCGAPIClient: url: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 12
        addHeaders(to: &request)
        
        print("🌐 PokemonTCGAPIClient: GET \(url)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("📡 PokemonTCGAPIClient: Response status: \(httpResponse.statusCode)")
        let bodyPreview = String(data: data, encoding: .utf8) ?? "<no body>"
        let preview = String(bodyPreview.prefix(400))
        print("📡 PokemonTCGAPIClient: Body preview: \(preview)")
        
        if httpResponse.statusCode == 400 || httpResponse.statusCode == 404 {
            return QueryAttemptResult(statusCode: httpResponse.statusCode, matches: [])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        if data.isEmpty {
            print("⚠️ PokemonTCGAPIClient: Empty body for 2xx response")
            return QueryAttemptResult(statusCode: httpResponse.statusCode, matches: [])
        }
        
        let searchResponse: SearchCardsResponse
        do {
            searchResponse = try JSONDecoder().decode(SearchCardsResponse.self, from: data)
        } catch {
            print("❌ PokemonTCGAPIClient: Decoding failed")
            return QueryAttemptResult(statusCode: httpResponse.statusCode, matches: [])
        }
        
        print("✅ PokemonTCGAPIClient: Found \(searchResponse.data.count) cards")
        
        return QueryAttemptResult(
            statusCode: httpResponse.statusCode,
            matches: searchResponse.data.map { $0.toCardMatch() }
        )
    }
    
    private func addHeaders(to request: inout URLRequest) {
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Decked/1.0", forHTTPHeaderField: "User-Agent")
        
        if let apiKey = apiKey {
            request.setValue(apiKey, forHTTPHeaderField: "X-Api-Key")
        }
    }
    
    private func makeCardsURL(q: String, pageSize: Int) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.pokemontcg.io"
        components.path = "/v2/cards"
        components.queryItems = [
            URLQueryItem(name: "q", value: q),
            URLQueryItem(name: "pageSize", value: String(pageSize))
        ]
        return components.url
    }
}

// MARK: - Search Result + Query Builder

struct CardSearchResult {
    let matches: [CardMatch]
    let attemptedQueries: [String]
    let warning: String?
}

private struct QueryAttemptResult {
    let statusCode: Int
    let matches: [CardMatch]
}

private struct SearchStrategy {
    let label: String
    let query: String
}

private enum CardSearchQueryBuilder {
    static func strategies(from hint: ParsedCardHint) -> [SearchStrategy] {
        var strategies: [SearchStrategy] = []
        let cleanedName = hint.nameGuess.map { cleanName($0) }
        
        if let name = cleanedName, !name.isEmpty {
            let query = "name:\(name)"
            strategies.append(SearchStrategy(label: "name loose", query: query))
        }
        
        if let name = cleanedName, !name.isEmpty {
            let query = "name:\"\(name)\""
            strategies.append(SearchStrategy(label: "name exact", query: query))
        }
        
        if (cleanedName == nil || cleanedName?.isEmpty == true), !hint.nameFallbacks.isEmpty
        {
            for token in hint.nameFallbacks {
                let cleaned = cleanName(token)
                let loose = "name:\(cleaned)"
                strategies.append(SearchStrategy(label: "fallback name loose", query: loose))
                
                let exact = "name:\"\(cleaned)\""
                strategies.append(SearchStrategy(label: "fallback name exact", query: exact))
            }
        }
        
        if let name = cleanedName {
            let parts = name.split(separator: " ")
            if parts.count == 1, let word = parts.first, word.count >= 4 {
                let query = "name:\(word)*"
                strategies.append(SearchStrategy(label: "name prefix", query: query))
            }
        }
        
        if let number = hint.numberGuess {
            let normalizedNumber = normalizeNumber(number)
            let loose = "number:\(normalizedNumber)"
            strategies.append(SearchStrategy(label: "number loose", query: loose))
            
            let exact = "number:\"\(normalizedNumber)\""
            strategies.append(SearchStrategy(label: "number exact", query: exact))
        }
        
        if let setId = hint.setIdGuess, let number = hint.numberGuess {
            let normalizedNumber = normalizeNumber(number)
            let query = "set.id:\"\(setId)\" number:\"\(normalizedNumber)\""
            strategies.append(SearchStrategy(label: "set+number", query: query))
        }
        
        return strategies
    }
    
    static func cleanName(_ name: String) -> String {
        name.replacingOccurrences(of: "\"", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private static func normalizeNumber(_ number: String) -> String {
        let trimmed = number.trimmingCharacters(in: .whitespacesAndNewlines)
        let stripped = trimmed.replacingOccurrences(
            of: #"^0+"#,
            with: "",
            options: .regularExpression
        )
        return stripped.isEmpty ? "0" : stripped
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
