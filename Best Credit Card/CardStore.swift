//
//  CardStore.swift
//  Best Credit Card
//

import Foundation
import Observation

// MARK: - Reward Source

/// Indicates why a card was ranked at its rate — vendor bonus vs. category bonus vs. base.
enum RewardSource: Equatable {
    case vendorBonus(vendorName: String)
    case categoryBonus
    case baseRate
}

/// A card paired with its effective reward rate and the source of that rate.
struct RankedCard: Identifiable {
    let card: CreditCard
    let rate: Double
    let source: RewardSource

    var id: UUID { card.id }
}

// MARK: - Card Store

@Observable
class CardStore {
    var cards: [CreditCard] = []

    private let storageKey = "saved_cards_v1"

    init() {
        load()
    }

    func addCard(_ card: CreditCard) {
        cards.append(card)
        save()
    }

    func updateCard(_ card: CreditCard) {
        guard let index = cards.firstIndex(where: { $0.id == card.id }) else { return }
        cards[index] = card
        save()
    }

    func deleteCards(at offsets: IndexSet) {
        offsets.sorted().reversed().forEach { cards.remove(at: $0) }
        save()
    }

    /// Returns all cards sorted by their reward rate for the given category, highest first.
    /// Use this when there is no specific merchant name (e.g. "By Category" mode).
    func rankedCards(for category: RewardCategory) -> [(card: CreditCard, rate: Double)] {
        cards
            .map { ($0, $0.reward(for: category)) }
            .sorted { $0.1 > $1.1 }
    }

    /// Returns all cards ranked by effective reward for a specific merchant.
    /// Checks vendor bonuses first; falls back to category rate.
    func rankedCards(for category: RewardCategory, merchantName: String) -> [RankedCard] {
        cards
            .map { card -> RankedCard in
                if let vendor = card.vendorReward(for: merchantName) {
                    return RankedCard(card: card, rate: vendor.rewardRate,
                                      source: .vendorBonus(vendorName: vendor.vendorName))
                }
                let categoryRate = card.reward(for: category)
                let source: RewardSource = card.rewards[category.rawValue] != nil
                    ? .categoryBonus
                    : .baseRate
                return RankedCard(card: card, rate: categoryRate, source: source)
            }
            .sorted { $0.rate > $1.rate }
    }

    // MARK: - Persistence

    private func save() {
        guard let data = try? JSONEncoder().encode(cards) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode([CreditCard].self, from: data)
        else { return }
        cards = decoded
    }
}
