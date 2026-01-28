//
//  BinderEntity+CoreDataClass.swift
//  Decked
//

import Foundation
import CoreData

@objc(BinderEntity)
public class BinderEntity: NSManagedObject {
    
    /// Total number of cards in this binder
    var cardCount: Int {
        cards?.count ?? 0
    }
    
    /// Total value of all cards in this binder
    var totalValue: Double {
        guard let cards = cards as? Set<OwnedCardEntity> else { return 0 }
        return cards.reduce(0) { total, card in
            let price = card.suggestedPrice > 0 ? card.suggestedPrice : card.purchasePrice
            return total + (price * Double(card.quantity))
        }
    }
    
    /// Preview image URL (first card's image)
    var previewImageURL: URL? {
        guard let cards = cards as? Set<OwnedCardEntity>,
              let firstCard = cards.first,
              let urlString = firstCard.catalogCard?.imageSmallURL else {
            return nil
        }
        return URL(string: urlString)
    }
}
