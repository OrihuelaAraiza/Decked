//
//  PersistenceController.swift
//  Decked
//
//  Core Data persistence controller
//

import CoreData
import Foundation

final class PersistenceController {
    
    // MARK: - Singleton
    
    static let shared = PersistenceController()
    
    // MARK: - Preview
    
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        
        // Create sample data for previews
        let binder = BinderEntity(context: context)
        binder.id = UUID()
        binder.title = "My Favorites"
        binder.createdAt = Date()
        
        let catalogCard = CatalogCardEntity(context: context)
        catalogCard.id = "base1-4"
        catalogCard.name = "Charizard"
        catalogCard.setId = "base1"
        catalogCard.setName = "Base Set"
        catalogCard.number = "4"
        catalogCard.rarity = "Rare Holo"
        catalogCard.imageSmallURL = "https://images.pokemontcg.io/base1/4.png"
        catalogCard.imageLargeURL = "https://images.pokemontcg.io/base1/4_hires.png"
        
        let ownedCard = OwnedCardEntity(context: context)
        ownedCard.id = UUID()
        ownedCard.language = "EN"
        ownedCard.condition = "NM"
        ownedCard.isFoil = true
        ownedCard.quantity = 1
        ownedCard.createdAt = Date()
        ownedCard.catalogCard = catalogCard
        ownedCard.binder = binder
        
        do {
            try context.save()
        } catch {
            print("❌ Preview data creation failed: \(error)")
        }
        
        return controller
    }()
    
    // MARK: - Container
    
    let container: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    // MARK: - Initialization
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "DeckedModel")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                print("❌ Core Data failed to load: \(error.localizedDescription)")
                fatalError("Core Data store failed to load: \(error)")
            }
            
            print("✅ Core Data loaded successfully")
            print("📁 Store URL: \(description.url?.absoluteString ?? "unknown")")
        }
        
        // Merge policy
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // MARK: - Save Context
    
    func save() {
        let context = container.viewContext
        
        guard context.hasChanges else {
            return
        }
        
        do {
            try context.save()
            print("✅ Core Data context saved")
        } catch {
            print("❌ Failed to save Core Data context: \(error)")
        }
    }
    
    // MARK: - Background Context
    
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    // MARK: - Batch Operations
    
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask(block)
    }
}
