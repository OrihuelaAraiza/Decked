//
//  BinderEntity+CoreDataProperties.swift
//  Decked
//

import Foundation
import CoreData

extension BinderEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<BinderEntity> {
        return NSFetchRequest<BinderEntity>(entityName: "BinderEntity")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var createdAt: Date
    @NSManaged public var cards: NSSet?
}

// MARK: - Generated accessors for cards
extension BinderEntity {
    
    @objc(addCardsObject:)
    @NSManaged public func addToCards(_ value: OwnedCardEntity)
    
    @objc(removeCardsObject:)
    @NSManaged public func removeFromCards(_ value: OwnedCardEntity)
    
    @objc(addCards:)
    @NSManaged public func addToCards(_ values: NSSet)
    
    @objc(removeCards:)
    @NSManaged public func removeFromCards(_ values: NSSet)
}

extension BinderEntity : Identifiable {
}
