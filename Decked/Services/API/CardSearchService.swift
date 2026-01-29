//
//  CardSearchService.swift
//  Decked
//
//  Generic card search service protocol
//

import Foundation

protocol CardSearchService {
    func searchCardsWithAttempts(hint: ParsedCardHint) async throws -> CardSearchResult
    func getCard(id: String) async throws -> CardMatch?
}
