//
//  CollectionViewModel.swift
//  Decked
//
//  ViewModel for collection management with Core Data
//

import Foundation
import Combine
import CoreData

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

@MainActor
final class CollectionViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var ownedCards: [OwnedCardEntity] = []
    @Published private(set) var isLoading = false
    @Published var searchText = ""
    @Published var filter: CollectionFilter = .all
    @Published var sortOption: CollectionSortOption = .dateAdded
    
    // MARK: - Properties
    
    private let viewContext: NSManagedObjectContext
    
    // MARK: - Computed Properties
    
    var filteredCards: [OwnedCardEntity] {
        var result = ownedCards
        
        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { card in
                guard let catalogCard = card.catalogCard else { return false }
                return catalogCard.name.localizedCaseInsensitiveContains(searchText) ||
                       catalogCard.setName.localizedCaseInsensitiveContains(searchText) ||
                       catalogCard.number.contains(searchText)
            }
        }
        
        // Apply category filter
        switch filter {
        case .all:
            break
        case .rare:
            let rareRarities: [CardRarity] = [.rare, .holo, .ultraRare, .secretRare, .specialArt, .illustrationRare]
            result = result.filter { card in
                guard let rarity = card.catalogCard?.rarity else { return false }
                return rareRarities.contains(CardRarity.from(rarity))
            }
        case .foil:
            result = result.filter { $0.isFoil }
        default:
            // Pokemon, Trainer, Energy filters not applicable without supertype data
            break
        }
        
        // Apply sort
        switch sortOption {
        case .dateAdded:
            result.sort { $0.createdAt > $1.createdAt }
        case .name:
            result.sort { ($0.catalogCard?.name ?? "") < ($1.catalogCard?.name ?? "") }
        case .value:
            result.sort { $0.totalValue > $1.totalValue }
        case .rarity:
            result.sort { 
                rarityOrder(CardRarity.from($0.catalogCard?.rarity ?? "")) > 
                rarityOrder(CardRarity.from($1.catalogCard?.rarity ?? ""))
            }
        }
        
        return result
    }
    
    var totalCards: Int {
        ownedCards.reduce(0) { $0 + Int($1.quantity) }
    }
    
    var uniqueCards: Int {
        ownedCards.count
    }
    
    var totalValue: Double {
        ownedCards.reduce(0) { $0 + $1.totalValue }
    }
    
    var formattedTotalValue: String {
        if totalValue >= 1000 {
            return String(format: "$%.1fk", totalValue / 1000)
        }
        return String(format: "$%.0f", totalValue)
    }
    
    // MARK: - Initialization
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }
    
    // MARK: - Public Methods
    
    func loadCollection() async {
        isLoading = true
        
        let request = OwnedCardEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \OwnedCardEntity.createdAt, ascending: false)
        ]
        request.relationshipKeyPathsForPrefetching = ["catalogCard", "binder"]
        
        do {
            ownedCards = try viewContext.fetch(request)
            print("✅ Loaded \(ownedCards.count) cards from collection")
        } catch {
            print("❌ Failed to load collection: \(error)")
        }
        
        isLoading = false
    }
    
    func deleteCard(_ card: OwnedCardEntity) async {
        viewContext.delete(card)
        
        do {
            try viewContext.save()
            await loadCollection()
            print("✅ Deleted card from collection")
        } catch {
            print("❌ Failed to delete card: \(error)")
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
