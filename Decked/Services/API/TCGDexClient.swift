//
//  TCGDexClient.swift
//  Decked
//
//  TCGdex API client for Pokémon TCG card search
//

import Foundation

final class TCGDexClient: CardSearchService {
    
    private let session: URLSession
    private let baseURL = "https://api.tcgdex.net/v2"
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func searchCardsWithAttempts(hint: ParsedCardHint) async throws -> CardSearchResult {
        print("🔍 TCGDexClient: Searching with hint: \(hint)")
        
        let strategies = TCGDexQueryBuilder.strategies(from: hint)
        print("🔎 TCGDexClient: queries: \(strategies.map { $0.label })")
        
        var attempted: [String] = []
        
        for strategy in strategies {
            attempted.append(strategy.label)
            
            switch strategy.kind {
            case .setAndNumber(let setCode, let number):
                if let results = try await searchBySetAndNumber(setCode: setCode, number: number) {
                    if !results.isEmpty {
                        print("✅ TCGDexClient: winning strategy \(strategy.label)")
                        return CardSearchResult(matches: results, attemptedQueries: attempted, warning: nil)
                    }
                }
            case .name(let name, let language):
                let results = try await searchByName(name: name, language: language)
                if !results.isEmpty {
                    print("✅ TCGDexClient: winning strategy \(strategy.label)")
                    return CardSearchResult(matches: results, attemptedQueries: attempted, warning: nil)
                }
            case .number(let number):
                let results = try await searchByNumber(number: number)
                if !results.isEmpty {
                    print("✅ TCGDexClient: winning strategy \(strategy.label)")
                    return CardSearchResult(matches: results, attemptedQueries: attempted, warning: nil)
                }
            }
        }
        
        print("❌ TCGDexClient: No cards found after all strategies")
        return CardSearchResult(matches: [], attemptedQueries: attempted, warning: nil)
    }
    
    func getCard(id: String) async throws -> CardMatch? {
        let lang = "en"
        guard let url = makeURL(path: "/\(lang)/cards/\(id)", queryItems: nil) else {
            return nil
        }
        
        let card: TCGDexCard
        do {
            card = try await fetchObject(url: url, as: TCGDexCard.self)
        } catch {
            return nil
        }
        
        return card.toCardMatch()
    }
    
    // MARK: - Search Strategies
    
    private func searchBySetAndNumber(setCode: String, number: String) async throws -> [CardMatch]? {
        let lang = "en"
        let normalizedNumber = TCGDexQueryBuilder.normalizeNumber(number)
        
        guard let setId = try await resolveSetId(for: setCode, language: lang) else {
            return nil
        }
        
        let path = "/\(lang)/sets/\(setId)/\(normalizedNumber)"
        guard let url = makeURL(path: path, queryItems: nil) else {
            return nil
        }
        
        do {
            let card = try await fetchObject(url: url, as: TCGDexCard.self)
            let match = card.toCardMatch(matchedFields: ["set", "number"])
            return [match]
        } catch {
            return []
        }
    }
    
    private func searchByName(name: String, language: String) async throws -> [CardMatch] {
        let queryItems = [
            URLQueryItem(name: "name", value: name),
            URLQueryItem(name: "pagination:itemsPerPage", value: "20")
        ]
        
        guard let url = makeURL(path: "/\(language)/cards", queryItems: queryItems) else {
            return []
        }
        
        let cards = try await fetchArray(url: url, as: TCGDexCardBrief.self)
        if cards.isEmpty { return [] }
        
        return try await hydrateCards(cards.map { $0.id })
    }
    
    private func searchByNumber(number: String) async throws -> [CardMatch] {
        let lang = "en"
        let normalized = TCGDexQueryBuilder.normalizeNumber(number)
        let queryItems = [
            URLQueryItem(name: "localId", value: normalized),
            URLQueryItem(name: "pagination:itemsPerPage", value: "20")
        ]
        
        guard let url = makeURL(path: "/\(lang)/cards", queryItems: queryItems) else {
            return []
        }
        
        let cards = try await fetchArray(url: url, as: TCGDexCardBrief.self)
        if cards.isEmpty { return [] }
        
        return try await hydrateCards(cards.map { $0.id })
    }
    
    // MARK: - Helpers
    
    private func resolveSetId(for setCode: String, language: String) async throws -> String? {
        let queryItems = [
            URLQueryItem(name: "tcgOnline", value: setCode.uppercased()),
            URLQueryItem(name: "pagination:itemsPerPage", value: "5")
        ]
        guard let url = makeURL(path: "/\(language)/sets", queryItems: queryItems) else {
            return nil
        }
        
        let sets = try await fetchArray(url: url, as: TCGDexSetBrief.self)
        return sets.first?.id
    }
    
    private func hydrateCards(_ ids: [String]) async throws -> [CardMatch] {
        if ids.isEmpty { return [] }
        let lang = "en"
        
        return try await withThrowingTaskGroup(of: CardMatch?.self) { group in
            for id in ids.prefix(10) {
                group.addTask {
                    guard let url = self.makeURL(path: "/\(lang)/cards/\(id)", queryItems: nil) else {
                        return nil
                    }
                    do {
                        let card = try await self.fetchObject(url: url, as: TCGDexCard.self)
                        return card.toCardMatch()
                    } catch {
                        return nil
                    }
                }
            }
            
            var results: [CardMatch] = []
            for try await match in group {
                if let match = match {
                    results.append(match)
                }
            }
            return results
        }
    }
    
    private func makeURL(path: String, queryItems: [URLQueryItem]?) -> URL? {
        var components = URLComponents(string: baseURL)
        components?.path = path
        components?.queryItems = queryItems
        return components?.url
    }
    
    private func fetchObject<T: Decodable>(url: URL, as type: T.Type) async throws -> T {
        var request = URLRequest(url: url)
        request.timeoutInterval = 12
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Decked/1.0", forHTTPHeaderField: "User-Agent")
        
        print("🌐 TCGDexClient: GET \(url.absoluteString)")
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("📡 TCGDexClient: status \(httpResponse.statusCode)")
        let bodyPreview = String(data: data, encoding: .utf8) ?? "<no body>"
        print("📡 TCGDexClient: Body preview: \(String(bodyPreview.prefix(300)))")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    private func fetchArray<T: Decodable>(url: URL, as type: T.Type) async throws -> [T] {
        var request = URLRequest(url: url)
        request.timeoutInterval = 12
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Decked/1.0", forHTTPHeaderField: "User-Agent")
        
        print("🌐 TCGDexClient: GET \(url.absoluteString)")
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("📡 TCGDexClient: status \(httpResponse.statusCode)")
        let bodyPreview = String(data: data, encoding: .utf8) ?? "<no body>"
        print("📡 TCGDexClient: Body preview: \(String(bodyPreview.prefix(300)))")
        
        if httpResponse.statusCode == 404 {
            return []
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        if data.isEmpty {
            return []
        }
        
        do {
            return try JSONDecoder().decode([T].self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
}

// MARK: - Query Builder

private struct TCGDexStrategy {
    enum Kind {
        case setAndNumber(setCode: String, number: String)
        case name(name: String, language: String)
        case number(number: String)
    }
    
    let label: String
    let kind: Kind
}

private enum TCGDexQueryBuilder {
    static func strategies(from hint: ParsedCardHint) -> [TCGDexStrategy] {
        var strategies: [TCGDexStrategy] = []
        let language = mapLanguage(hint.language)
        let name = hint.nameGuess?.trimmingCharacters(in: .whitespacesAndNewlines)
        let number = hint.numberGuess?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let setCode = hint.setIdGuess, let number = number, !setCode.isEmpty {
            strategies.append(
                TCGDexStrategy(
                    label: "set:\(setCode) number:\(number)",
                    kind: .setAndNumber(setCode: setCode, number: number)
                )
            )
        }
        
        if let name = name, !name.isEmpty {
            strategies.append(
                TCGDexStrategy(
                    label: "name:\(name) lang:\(language)",
                    kind: .name(name: name, language: language)
                )
            )
        }
        
        if let name = name, !name.isEmpty, language != "en" {
            strategies.append(
                TCGDexStrategy(
                    label: "name:\(name) lang:en",
                    kind: .name(name: name, language: "en")
                )
            )
        }
        
        if let number = number, !number.isEmpty {
            strategies.append(
                TCGDexStrategy(
                    label: "number:\(number)",
                    kind: .number(number: number)
                )
            )
        }
        
        return strategies
    }
    
    static func mapLanguage(_ language: CardLanguage?) -> String {
        switch language {
        case .spanish:
            return "es"
        case .japanese:
            return "ja"
        default:
            return "en"
        }
    }
    
    static func normalizeNumber(_ number: String) -> String {
        let stripped = number.replacingOccurrences(
            of: #"^0+"#,
            with: "",
            options: .regularExpression
        )
        return stripped.isEmpty ? "0" : stripped
    }
}

// MARK: - DTOs

private struct TCGDexCardBrief: Decodable {
    let id: String
    let localId: String?
    let name: String
    let image: String?
}

private struct TCGDexSetBrief: Decodable {
    let id: String
    let name: String
    let tcgOnline: String?
}

private struct TCGDexCard: Decodable {
    let id: String
    let localId: String?
    let name: String
    let rarity: String?
    let image: String?
    let hp: String?
    let types: [String]?
    let set: TCGDexSet
    
    func toCardMatch(matchedFields: [String] = ["name"]) -> CardMatch {
        CardMatch(
            id: id,
            card: Card(
                id: id,
                name: name,
                setId: set.id,
                setName: set.name,
                number: localId ?? "",
                rarity: CardRarity.from(rarity ?? "Common"),
                imageURL: image.flatMap { URL(string: $0) },
                imageURLHighRes: image.flatMap { URL(string: $0) },
                artist: nil,
                supertype: nil,
                subtypes: nil,
                hp: hp,
                types: types,
                nationalPokedexNumber: nil,
                marketPrice: nil,
                lowPrice: nil,
                highPrice: nil,
                setSeries: nil,
                setReleaseDate: nil,
                setTotalCards: set.cardCount
            ),
            confidence: 1.0,
            matchedFields: matchedFields
        )
    }
}

private struct TCGDexSet: Decodable {
    let id: String
    let name: String
    let cardCount: Int?
    let tcgOnline: String?
}
