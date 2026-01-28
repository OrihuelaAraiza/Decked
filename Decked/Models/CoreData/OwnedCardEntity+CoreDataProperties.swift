//
//  OwnedCardEntity+CoreDataProperties.swift
//  Decked
//

import Foundation
import CoreData

extension OwnedCardEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<OwnedCardEntity> {
        return NSFetchRequest<OwnedCardEntity>(entityName: "OwnedCardEntity")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var language: String
    @NSManaged public var condition: String
    @NSManaged public var isFoil: Bool
    @NSManaged public var quantity: Int16
    @NSManaged public var purchasePrice: Double
    @NSManaged public var suggestedPrice: Double
    @NSManaged public var createdAt: Date
    @NSManaged public var catalogCard: CatalogCardEntity?
    @NSManaged public var binder: BinderEntity?
}

extension OwnedCardEntity : Identifiable {
}
