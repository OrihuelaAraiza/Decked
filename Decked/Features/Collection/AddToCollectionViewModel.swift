//
//  AddToCollectionViewModel.swift
//  Decked
//
//  ViewModel for adding cards to collection with Core Data
//

import Foundation
import Combine
import CoreData

@MainActor
final class AddToCollectionViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var selectedLanguage: CardLanguage = .english
    @Published var selectedCondition: CardCondition = .nearMint
    @Published var isFoil: Bool = false
    @Published var quantity: Int = 1
    @Published var pricePaid: String = ""
    @Published var selectedBinder: BinderEntity?
    @Published var binders: [BinderEntity] = []
    @Published var showingCreateBinder = false
    
    @Published private(set) var isSaving = false
    @Published private(set) var error: String?
    @Published private(set) var didSave = false
    
    // MARK: - Properties
    
    let card: Card
    private let viewContext: NSManagedObjectContext
    
    // MARK: - Computed Properties
    
    var pricePaidValue: Double? {
        Double(pricePaid)
    }
    
    var canSave: Bool {
        selectedBinder != nil && !isSaving
    }
    
    // MARK: - Initialization
    
    init(card: Card, viewContext: NSManagedObjectContext) {
        self.card = card
        self.viewContext = viewContext
        Task {
            await loadBinders()
        }
    }
    
    // MARK: - Public Methods
    
    func loadBinders() async {
        let request = BinderEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \BinderEntity.createdAt, ascending: false)
        ]
        
        do {
            binders = try viewContext.fetch(request)
            
            // Auto-select first binder if available
            if selectedBinder == nil, let firstBinder = binders.first {
                selectedBinder = firstBinder
            }
            
            print("✅ Loaded \(binders.count) binders")
        } catch {
            print("❌ Failed to load binders: \(error)")
            self.error = "Failed to load binders"
        }
    }
    
    func addToCollection() async {
        guard !isSaving else { return }
        guard let binder = selectedBinder else {
            error = "Please select a binder"
            return
        }
        
        isSaving = true
        error = nil
        
        do {
            // 1. Upsert CatalogCardEntity
            let catalogCard = try upsertCatalogCard()
            
            // 2. Create OwnedCardEntity
            let ownedCard = OwnedCardEntity(context: viewContext)
            ownedCard.id = UUID()
            ownedCard.languageEnum = selectedLanguage
            ownedCard.conditionEnum = selectedCondition
            ownedCard.isFoil = isFoil
            ownedCard.quantity = Int16(quantity)
            ownedCard.purchasePrice = pricePaidValue ?? 0
            ownedCard.suggestedPrice = card.marketPrice ?? 0
            ownedCard.createdAt = Date()
            ownedCard.catalogCard = catalogCard
            ownedCard.binder = binder
            
            // 3. Save
            try viewContext.save()
            
            print("✅ Added card to collection")
            didSave = true
            
        } catch {
            print("❌ Failed to add card: \(error)")
            self.error = "Failed to add card: \(error.localizedDescription)"
        }
        
        isSaving = false
    }
    
    func createNewBinder(title: String) async {
        let binder = BinderEntity(context: viewContext)
        binder.id = UUID()
        binder.title = title
        binder.createdAt = Date()
        
        do {
            try viewContext.save()
            await loadBinders()
            selectedBinder = binder
            print("✅ Created new binder: \(title)")
        } catch {
            print("❌ Failed to create binder: \(error)")
            self.error = "Failed to create binder"
        }
    }
    
    // MARK: - Private Methods
    
    private func upsertCatalogCard() throws -> CatalogCardEntity {
        // Check if catalog card already exists
        let request = CatalogCardEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", card.id)
        request.fetchLimit = 1
        
        if let existing = try viewContext.fetch(request).first {
            print("📚 Using existing catalog card: \(card.name)")
            return existing
        }
        
        // Create new catalog card
        let catalogCard = CatalogCardEntity(context: viewContext)
        catalogCard.id = card.id
        catalogCard.name = card.name
        catalogCard.setId = card.setId
        catalogCard.setName = card.setName
        catalogCard.number = card.number
        catalogCard.rarity = card.rarity.rawValue
        catalogCard.imageSmallURL = card.imageURL?.absoluteString
        catalogCard.imageLargeURL = card.imageLargeURL?.absoluteString
        
        print("📚 Created new catalog card: \(card.name)")
        return catalogCard
    }
}
