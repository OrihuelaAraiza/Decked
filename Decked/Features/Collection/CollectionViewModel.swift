//
//  CollectionViewModel.swift
//  Decked
//
//  ViewModel for collection management
//

import Foundation
import Combine

// MARK: - Collection Filter

enum CollectionFilter: CaseIterable {
    case all
    case pokemon
    case trainer
    case energy
    case rare
    case foil
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .pokemon: return "Pokémon"
        case .trainer: return "Trainer"
        case .energy: return "Energy"
        case .rare: return "Rare+"
        case .foil: return "Foil"
        }
    }
}

// MARK: - Sort Option

enum CollectionSortOption {
    case dateAdded
    case name
    case value
    case rarity
}

// MARK: - Collection ViewModel

final class CollectionViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var cards: [CollectionCard] = []
    @Published private(set) var isLoading = false
    @Published var searchText = ""
    @Published var filter: CollectionFilter = .all
    @Published var sortOption: CollectionSortOption = .dateAdded
    
    // MARK: - Services
    
    private let collectionService: CollectionServiceProtocol
    
    // MARK: - Computed Properties
    
    var filteredCards: [CollectionCard] {
        var result = cards
        
        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { card in
                card.card.name.localizedCaseInsensitiveContains(searchText) ||
                card.card.setName.localizedCaseInsensitiveContains(searchText) ||
                card.card.number.contains(searchText)
            }
        }
        
        // Apply category filter
        switch filter {
        case .all:
            break
        case .pokemon:
            result = result.filter { $0.card.supertype == "Pokémon" }
        case .trainer:
            result = result.filter { $0.card.supertype == "Trainer" }
        case .energy:
            result = result.filter { $0.card.supertype == "Energy" }
        case .rare:
            let rareRarities: [CardRarity] = [.rare, .holo, .ultraRare, .secretRare, .specialArt, .illustrationRare]
            result = result.filter { rareRarities.contains($0.card.rarity) }
        case .foil:
            result = result.filter { $0.isFoil }
        }
        
        // Apply sort
        switch sortOption {
        case .dateAdded:
            result.sort { $0.dateAdded > $1.dateAdded }
        case .name:
            result.sort { $0.card.name < $1.card.name }
        case .value:
            result.sort { ($0.estimatedValue ?? 0) > ($1.estimatedValue ?? 0) }
        case .rarity:
            result.sort { rarityOrder($0.card.rarity) > rarityOrder($1.card.rarity) }
        }
        
        return result
    }
    
    var totalCards: Int {
        cards.reduce(0) { $0 + $1.quantity }
    }
    
    var uniqueCards: Int {
        cards.count
    }
    
    var totalValue: Double {
        cards.compactMap { $0.estimatedValue }.reduce(0, +)
    }
    
    var formattedTotalValue: String {
        if totalValue >= 1000 {
            return String(format: "$%.1fk", totalValue / 1000)
        }
        return String(format: "$%.0f", totalValue)
    }
    
    // MARK: - Initialization
    
    init(collectionService: CollectionServiceProtocol = CollectionService.shared) {
        self.collectionService = collectionService
    }
    
    // MARK: - Public Methods
    
    @MainActor
    func loadCollection() async {
        isLoading = true
        cards = await collectionService.getCards()
        isLoading = false
    }
    
    @MainActor
    func deleteCard(_ cardId: UUID) async {
        do {
            try await collectionService.removeCard(cardId)
            await loadCollection()
        } catch {
            print("Failed to delete card: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func rarityOrder(_ rarity: CardRarity) -> Int {
        switch rarity {
        case .common: return 0
        case .uncommon: return 1
        case .rare: return 2
        case .holo: return 3
        case .ultraRare: return 4
        case .illustrationRare: return 5
        case .specialArt: return 6
        case .secretRare: return 7
        case .unknown: return -1
        }
    }
}
