//
//  CardStore.swift
//  Best Credit Card
//

import Foundation
import Observation

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
    func rankedCards(for category: RewardCategory) -> [(card: CreditCard, rate: Double)] {
        cards
            .map { ($0, $0.reward(for: category)) }
            .sorted { $0.1 > $1.1 }
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
