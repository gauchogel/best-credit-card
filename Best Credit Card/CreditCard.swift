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

// MARK: - Vendor Bonus

struct VendorBonus: Codable, Identifiable {
    var id: UUID = UUID()
    var vendorName: String      // e.g. "Amazon", "Whole Foods", "United"
    var rewardRate: Double      // e.g. 5.0 for 5%
}

// MARK: - Credit Card

struct CreditCard: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var lastFour: String
    var cardColor: CardColor
    /// Reward rates by RewardCategory.rawValue → percentage (e.g. 3.0 = 3 %)
    var rewards: [String: Double]
    /// Default reward for any category not explicitly set
    var baseReward: Double
    /// Vendor-specific bonus rates (e.g. 5% at Amazon, 14x at Hilton)
    var vendorBonuses: [VendorBonus]

    // MARK: Memberwise init

    init(
        id: UUID = UUID(),
        name: String,
        lastFour: String,
        cardColor: CardColor,
        rewards: [String: Double],
        baseReward: Double,
        vendorBonuses: [VendorBonus] = []
    ) {
        self.id = id
        self.name = name
        self.lastFour = lastFour
        self.cardColor = cardColor
        self.rewards = rewards
        self.baseReward = baseReward
        self.vendorBonuses = vendorBonuses
    }

    // MARK: Backward-compatible decoding

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id            = try container.decode(UUID.self, forKey: .id)
        name          = try container.decode(String.self, forKey: .name)
        lastFour      = try container.decode(String.self, forKey: .lastFour)
        cardColor     = try container.decode(CardColor.self, forKey: .cardColor)
        rewards       = try container.decode([String: Double].self, forKey: .rewards)
        baseReward    = try container.decode(Double.self, forKey: .baseReward)
        // Gracefully handle missing key from older saved data
        vendorBonuses = (try? container.decode([VendorBonus].self, forKey: .vendorBonuses)) ?? []
    }

    // MARK: Reward lookups

    /// Category-based reward rate.
    func reward(for category: RewardCategory) -> Double {
        rewards[category.rawValue] ?? baseReward
    }

    /// Returns the matching vendor bonus for a merchant name, if any.
    /// Uses bidirectional case-insensitive `contains` matching.
    func vendorReward(for merchantName: String) -> VendorBonus? {
        let lower = merchantName.lowercased()
        return vendorBonuses.first { bonus in
            let bonusLower = bonus.vendorName.lowercased()
            return lower.contains(bonusLower) || bonusLower.contains(lower)
        }
    }

    /// Effective reward rate for a specific merchant — vendor bonus wins if present.
    func effectiveReward(for merchantName: String, category: RewardCategory) -> Double {
        vendorReward(for: merchantName)?.rewardRate ?? reward(for: category)
    }
}
