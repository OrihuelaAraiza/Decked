//
//  CatalogCardEntity+CoreDataProperties.swift
//  Decked
//

import Foundation
import CoreData

extension CatalogCardEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CatalogCardEntity> {
        return NSFetchRequest<CatalogCardEntity>(entityName: "CatalogCardEntity")
    }
    
    @NSManaged public var id: String
    @NSManaged public var name: String
    @NSManaged public var setId: String
    @NSManaged public var setName: String
    @NSManaged public var number: String
    @NSManaged public var rarity: String?
    @NSManaged public var imageSmallURL: String?
    @NSManaged public var imageLargeURL: String?
    @NSManaged public var ownedCards: NSSet?
}

// MARK: - Generated accessors for ownedCards
extension CatalogCardEntity {
    
    @objc(addOwnedCardsObject:)
    @NSManaged public func addToOwnedCards(_ value: OwnedCardEntity)
    
    @objc(removeOwnedCardsObject:)
    @NSManaged public func removeFromOwnedCards(_ value: OwnedCardEntity)
    
    @objc(addOwnedCards:)
    @NSManaged public func addToOwnedCards(_ values: NSSet)
    
    @objc(removeOwnedCards:)
    @NSManaged public func removeFromOwnedCards(_ values: NSSet)
}

extension CatalogCardEntity : Identifiable {
}
