//
//  OwnedCardEntity+CoreDataClass.swift
//  Decked
//

import Foundation
import CoreData

@objc(OwnedCardEntity)
public class OwnedCardEntity: NSManagedObject {
    
    /// Language enum
    var languageEnum: CardLanguage {
        get { CardLanguage(rawValue: language) ?? .english }
        set { language = newValue.rawValue }
    }
    
    /// Condition enum
    var conditionEnum: CardCondition {
        get { CardCondition(rawValue: condition) ?? .nearMint }
        set { condition = newValue.rawValue }
    }
    
    /// Total value (quantity * price)
    var totalValue: Double {
        let price = suggestedPrice > 0 ? suggestedPrice : purchasePrice
        return price * Double(quantity)
    }
    
    /// Display name
    var displayName: String {
        catalogCard?.name ?? "Unknown Card"
    }
}
