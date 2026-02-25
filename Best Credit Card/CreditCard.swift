//
//  CreditCard.swift
//  Best Credit Card
//

import Foundation

enum RewardCategory: String, CaseIterable, Codable, Identifiable {
    case dining        = "Dining"
    case groceries     = "Groceries"
    case gas           = "Gas & EV Charging"
    case travel        = "Travel"
    case streaming     = "Streaming"
    case onlineShopping = "Online Shopping"
    case wholesale     = "Wholesale Clubs"
    case drugstores    = "Drug Stores"
    case entertainment = "Entertainment"
    case transit       = "Transit"
    case other         = "Everything Else"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dining:         return "fork.knife"
        case .groceries:      return "cart.fill"
        case .gas:            return "fuelpump.fill"
        case .travel:         return "airplane"
        case .streaming:      return "play.rectangle.fill"
        case .onlineShopping: return "bag.fill"
        case .wholesale:      return "building.2.fill"
        case .drugstores:     return "pills.fill"
        case .entertainment:  return "ticket.fill"
        case .transit:        return "bus.fill"
        case .other:          return "creditcard.fill"
        }
    }
}

enum CardColor: String, CaseIterable, Codable, Identifiable {
    case ocean    = "Ocean"
    case midnight = "Midnight"
    case gold     = "Gold"
    case onyx     = "Onyx"
    case rose     = "Rose"
    case forest   = "Forest"
    case slate    = "Slate"
    case crimson  = "Crimson"

    var id: String { rawValue }
}

struct CreditCard: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var lastFour: String
    var cardColor: CardColor
    /// Reward rates by RewardCategory.rawValue → percentage (e.g. 3.0 = 3 %)
    var rewards: [String: Double]
    /// Default reward for any category not explicitly set
    var baseReward: Double

    func reward(for category: RewardCategory) -> Double {
        rewards[category.rawValue] ?? baseReward
    }
}
