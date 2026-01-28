//
//  AddToCollectionViewModel.swift
//  Decked
//
//  ViewModel for adding cards to collection
//

import Foundation
import Combine

final class AddToCollectionViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var selectedLanguage: CardLanguage = .english
    @Published var selectedCondition: CardCondition = .nearMint
    @Published var isFoil: Bool = false
    @Published var quantity: Int = 1
    @Published var pricePaid: String = ""
    @Published var selectedBinder: Binder?
    @Published var notes: String = ""
    
    @Published private(set) var isSaving = false
    @Published private(set) var error: String?
    
    // MARK: - Properties
    
    let card: Card
    private let collectionService: CollectionServiceProtocol
    
    // MARK: - Computed Properties
    
    var pricePaidValue: Double? {
        Double(pricePaid)
    }
    
    var estimatedValue: Double? {
        guard let marketPrice = card.marketPrice else { return nil }
        return marketPrice * selectedCondition.conditionMultiplier * Double(quantity)
    }
    
    var totalPricePaid: Double? {
        guard let price = pricePaidValue else { return nil }
        return price * Double(quantity)
    }
    
    // MARK: - Initialization
    
    init(card: Card, collectionService: CollectionServiceProtocol = CollectionService.shared) {
        self.card = card
        self.collectionService = collectionService
    }
    
    // MARK: - Public Methods
    
    @MainActor
    func addToCollection() async {
        guard !isSaving else { return }
        
        isSaving = true
        error = nil
        
        let collectionCard = CollectionCard(
            card: card,
            language: selectedLanguage,
            condition: selectedCondition,
            isFoil: isFoil,
            quantity: quantity,
            pricePaid: pricePaidValue,
            dateAdded: Date(),
            binderId: selectedBinder?.id,
            notes: notes.isEmpty ? nil : notes
        )
        
        do {
            try await collectionService.addCard(collectionCard)
        } catch {
            self.error = error.localizedDescription
        }
        
        isSaving = false
    }
    
    @MainActor
    func loadBinders() async {
        // Load available binders for selection
        // TODO: Implement when binder service is ready
    }
}

// MARK: - Collection Service Protocol

protocol CollectionServiceProtocol {
    func addCard(_ card: CollectionCard) async throws
    func removeCard(_ cardId: UUID) async throws
    func getCards() async -> [CollectionCard]
    func getCard(_ id: UUID) async -> CollectionCard?
}

// MARK: - Collection Service (UserDefaults-based for MVP)

final class CollectionService: CollectionServiceProtocol {
    
    static let shared = CollectionService()
    
    private let userDefaults = UserDefaults.standard
    private let collectionKey = "decked_collection"
    
    private init() {}
    
    func addCard(_ card: CollectionCard) async throws {
        var cards = await getCards()
        
        // Check if card already exists with same attributes
        if let existingIndex = cards.firstIndex(where: {
            $0.card.id == card.card.id &&
            $0.language == card.language &&
            $0.condition == card.condition &&
            $0.isFoil == card.isFoil
        }) {
            // Update quantity
            var existingCard = cards[existingIndex]
            existingCard = CollectionCard(
                id: existingCard.id,
                card: existingCard.card,
                language: existingCard.language,
                condition: existingCard.condition,
                isFoil: existingCard.isFoil,
                quantity: existingCard.quantity + card.quantity,
                pricePaid: card.pricePaid ?? existingCard.pricePaid,
                dateAdded: existingCard.dateAdded,
                binderId: card.binderId ?? existingCard.binderId,
                notes: card.notes ?? existingCard.notes
            )
            cards[existingIndex] = existingCard
        } else {
            cards.append(card)
        }
        
        try saveCards(cards)
    }
    
    func removeCard(_ cardId: UUID) async throws {
        var cards = await getCards()
        cards.removeAll { $0.id == cardId }
        try saveCards(cards)
    }
    
    func getCards() async -> [CollectionCard] {
        guard let data = userDefaults.data(forKey: collectionKey) else {
            return []
        }
        
        do {
            let cards = try JSONDecoder().decode([CollectionCard].self, from: data)
            return cards
        } catch {
            print("Failed to decode collection: \(error)")
            return []
        }
    }
    
    func getCard(_ id: UUID) async -> CollectionCard? {
        let cards = await getCards()
        return cards.first { $0.id == id }
    }
    
    private func saveCards(_ cards: [CollectionCard]) throws {
        let data = try JSONEncoder().encode(cards)
        userDefaults.set(data, forKey: collectionKey)
    }
}

// MARK: - Collection Errors

enum CollectionError: LocalizedError {
    case saveFailed
    case cardNotFound
    
    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "Failed to save card to collection"
        case .cardNotFound:
            return "Card not found in collection"
        }
    }
}
