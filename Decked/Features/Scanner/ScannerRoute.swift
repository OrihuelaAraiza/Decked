//
//  ScannerRoute.swift
//  Decked
//
//  Navigation routes for scanner flow
//

import Foundation

enum ScannerRoute: Hashable {
    case results([CardMatch])
    case detail(CardMatch)
    case noResults(ParsedCardHint, attemptedQueries: [String], warning: String?)
}
