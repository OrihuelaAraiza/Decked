//
//  CatalogCardEntity+CoreDataClass.swift
//  Decked
//

import Foundation
import CoreData

@objc(CatalogCardEntity)
public class CatalogCardEntity: NSManagedObject {
    
    /// Convert to domain Card model
    func toCard() -> Card {
        Card(
            id: id,
            name: name,
            setId: setId,
            setName: setName,
            number: number,
            rarity: CardRarity.from(rarity ?? "Common"),
            imageURL: imageSmallURL.flatMap(URL.init(string:)),
            imageURLHighRes: imageLargeURL.flatMap(URL.init(string:)),
            artist: nil,
            supertype: nil,
            subtypes: nil,
            hp: nil,
            types: nil,
            nationalPokedexNumber: nil,
            marketPrice: nil,
            lowPrice: nil,
            highPrice: nil,
            setSeries: nil,
            setReleaseDate: nil,
            setTotalCards: nil
        )
    }
    
    /// Total quantity owned across all instances
    var totalQuantity: Int {
        guard let ownedCards = ownedCards as? Set<OwnedCardEntity> else { return 0 }
        return ownedCards.reduce(0) { $0 + Int($1.quantity) }
    }
}
