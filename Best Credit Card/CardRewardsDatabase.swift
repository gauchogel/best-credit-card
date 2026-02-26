//
//  CardRewardsDatabase.swift
//  Best Credit Card
//

import Foundation

// MARK: - Known Card Rewards

struct KnownCardRewards {
    let cardName: String
    let baseReward: Double
    let categoryRewards: [RewardCategory: Double]
    let suggestedColor: CardColor
    let notes: String
}

// MARK: - Database

struct CardRewardsDatabase {

    /// Fuzzy search: returns entries whose cardName contains the query (case-insensitive).
    /// Prefix matches sort before substring-only matches.
    static func search(query: String) -> [KnownCardRewards] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard q.count >= 2 else { return [] }

        return entries
            .filter { $0.cardName.lowercased().contains(q) }
            .sorted { a, b in
                let aPrefix = a.cardName.lowercased().hasPrefix(q)
                let bPrefix = b.cardName.lowercased().hasPrefix(q)
                if aPrefix != bPrefix { return aPrefix }
                return a.cardName < b.cardName
            }
    }

    /// Exact match by canonical card name (used after OCR scan).
    static func exactMatch(for cardName: String) -> KnownCardRewards? {
        let lower = cardName.lowercased()
        return entries.first { $0.cardName.lowercased() == lower }
    }

    // MARK: - Entries

    static let entries: [KnownCardRewards] = [

        // ──────────────────────────────────────────────
        // MARK: Chase
        // ──────────────────────────────────────────────

        KnownCardRewards(
            cardName: "Chase Sapphire Reserve",
            baseReward: 1.0,
            categoryRewards: [.dining: 3.0, .travel: 5.0, .streaming: 10.0],
            suggestedColor: .midnight,
            notes: "Earns Ultimate Reward points. 5x on travel booked via Chase portal."
        ),
        KnownCardRewards(
            cardName: "Chase Sapphire Preferred",
            baseReward: 1.0,
            categoryRewards: [.dining: 3.0, .travel: 5.0, .onlineShopping: 3.0, .streaming: 3.0],
            suggestedColor: .midnight,
            notes: "Earns Ultimate Reward points. 5x on travel via Chase portal."
        ),
        KnownCardRewards(
            cardName: "Chase Freedom Unlimited",
            baseReward: 1.5,
            categoryRewards: [.dining: 3.0, .drugstores: 3.0, .travel: 5.0],
            suggestedColor: .ocean,
            notes: "1.5% flat rate plus bonus categories. 5x travel via Chase portal."
        ),
        KnownCardRewards(
            cardName: "Chase Freedom Flex",
            baseReward: 1.0,
            categoryRewards: [.dining: 3.0, .drugstores: 3.0, .travel: 5.0],
            suggestedColor: .ocean,
            notes: "Also earns 5% on rotating quarterly categories — enter current ones manually."
        ),
        KnownCardRewards(
            cardName: "Chase Ink Business Preferred",
            baseReward: 1.0,
            categoryRewards: [.travel: 3.0, .onlineShopping: 3.0, .streaming: 3.0],
            suggestedColor: .midnight,
            notes: "3x on first $150K in combined purchases per year."
        ),
        KnownCardRewards(
            cardName: "Chase Ink Business Unlimited",
            baseReward: 1.5,
            categoryRewards: [:],
            suggestedColor: .slate,
            notes: "1.5% flat rate on all purchases."
        ),
        KnownCardRewards(
            cardName: "Chase Ink Business Cash",
            baseReward: 1.0,
            categoryRewards: [.gas: 2.0],
            suggestedColor: .slate,
            notes: "5% on office supplies, internet, cable, phone (not modeled). 2% gas/dining."
        ),
        KnownCardRewards(
            cardName: "Chase Amazon Prime Visa",
            baseReward: 1.0,
            categoryRewards: [.onlineShopping: 5.0, .dining: 2.0, .gas: 2.0, .drugstores: 2.0],
            suggestedColor: .midnight,
            notes: "5% at Amazon.com and Whole Foods with Prime membership."
        ),

        // ──────────────────────────────────────────────
        // MARK: American Express
        // ──────────────────────────────────────────────

        KnownCardRewards(
            cardName: "Amex Platinum",
            baseReward: 1.0,
            categoryRewards: [.travel: 5.0, .dining: 1.0],
            suggestedColor: .slate,
            notes: "5x on flights booked directly or via Amex Travel. Points (MR)."
        ),
        KnownCardRewards(
            cardName: "Amex Gold",
            baseReward: 1.0,
            categoryRewards: [.dining: 4.0, .groceries: 4.0, .travel: 3.0],
            suggestedColor: .gold,
            notes: "4x dining worldwide. 4x US supermarkets (up to $25K/yr). 3x flights."
        ),
        KnownCardRewards(
            cardName: "Amex Green",
            baseReward: 1.0,
            categoryRewards: [.travel: 3.0, .transit: 3.0, .dining: 3.0],
            suggestedColor: .forest,
            notes: "3x on travel, transit, and restaurants. Points (MR)."
        ),
        KnownCardRewards(
            cardName: "Amex Blue Cash Preferred",
            baseReward: 1.0,
            categoryRewards: [.groceries: 6.0, .streaming: 6.0, .transit: 3.0, .gas: 3.0],
            suggestedColor: .ocean,
            notes: "6% groceries up to $6K/yr, then 1%. Cash back."
        ),
        KnownCardRewards(
            cardName: "Amex Blue Cash Everyday",
            baseReward: 1.0,
            categoryRewards: [.groceries: 3.0, .gas: 3.0, .onlineShopping: 3.0],
            suggestedColor: .ocean,
            notes: "3% groceries up to $6K/yr. Cash back."
        ),
        KnownCardRewards(
            cardName: "Amex Delta SkyMiles Platinum",
            baseReward: 1.0,
            categoryRewards: [.travel: 3.0, .dining: 2.0, .groceries: 2.0],
            suggestedColor: .midnight,
            notes: "3x Delta purchases. Earns SkyMiles."
        ),
        KnownCardRewards(
            cardName: "Amex Delta SkyMiles Gold",
            baseReward: 1.0,
            categoryRewards: [.travel: 2.0, .dining: 2.0, .groceries: 2.0],
            suggestedColor: .gold,
            notes: "2x Delta, restaurants, and US supermarkets. Earns SkyMiles."
        ),
        KnownCardRewards(
            cardName: "Amex Hilton Honors Aspire",
            baseReward: 3.0,
            categoryRewards: [.travel: 14.0, .dining: 7.0],
            suggestedColor: .midnight,
            notes: "14x at Hilton. 7x dining, flights, car rentals. Earns Hilton points."
        ),
        KnownCardRewards(
            cardName: "Amex Hilton Honors Surpass",
            baseReward: 3.0,
            categoryRewards: [.travel: 12.0, .dining: 6.0, .groceries: 6.0, .gas: 6.0],
            suggestedColor: .gold,
            notes: "12x at Hilton. 6x restaurants, supermarkets, gas. Hilton points."
        ),
        KnownCardRewards(
            cardName: "Amex Hilton Honors",
            baseReward: 3.0,
            categoryRewards: [.travel: 7.0, .dining: 5.0, .groceries: 5.0, .gas: 5.0],
            suggestedColor: .slate,
            notes: "7x at Hilton. 5x restaurants, supermarkets, gas. Hilton points."
        ),
        KnownCardRewards(
            cardName: "Amex Marriott Bonvoy Brilliant",
            baseReward: 2.0,
            categoryRewards: [.travel: 6.0, .dining: 3.0, .groceries: 3.0],
            suggestedColor: .midnight,
            notes: "6x at Marriott. 3x dining, groceries, flights. Marriott points."
        ),
        KnownCardRewards(
            cardName: "Amex Marriott Bonvoy",
            baseReward: 2.0,
            categoryRewards: [.travel: 4.0, .dining: 2.0, .groceries: 2.0],
            suggestedColor: .slate,
            notes: "4x at Marriott. 2x other travel, dining, groceries. Marriott points."
        ),

        // ──────────────────────────────────────────────
        // MARK: Citi
        // ──────────────────────────────────────────────

        KnownCardRewards(
            cardName: "Citi Double Cash",
            baseReward: 2.0,
            categoryRewards: [:],
            suggestedColor: .ocean,
            notes: "2% flat (1% on purchase + 1% on payment). Cash back."
        ),
        KnownCardRewards(
            cardName: "Citi Custom Cash",
            baseReward: 1.0,
            categoryRewards: [:],
            suggestedColor: .ocean,
            notes: "5% on your top eligible spend category each cycle (up to $500). Auto-detected."
        ),
        KnownCardRewards(
            cardName: "Citi Premier",
            baseReward: 1.0,
            categoryRewards: [.dining: 3.0, .groceries: 3.0, .gas: 3.0, .travel: 3.0],
            suggestedColor: .midnight,
            notes: "3x on multiple categories. Earns ThankYou Points."
        ),
        KnownCardRewards(
            cardName: "Citi Strata Premier",
            baseReward: 1.0,
            categoryRewards: [.dining: 3.0, .groceries: 3.0, .gas: 3.0, .travel: 3.0, .streaming: 3.0],
            suggestedColor: .midnight,
            notes: "3x dining, groceries, gas, travel, streaming. ThankYou Points."
        ),
        KnownCardRewards(
            cardName: "Citi Rewards+",
            baseReward: 1.0,
            categoryRewards: [.groceries: 2.0, .gas: 2.0],
            suggestedColor: .ocean,
            notes: "2x groceries and gas. Points rounded up to nearest 10. ThankYou Points."
        ),

        // ──────────────────────────────────────────────
        // MARK: Capital One
        // ──────────────────────────────────────────────

        KnownCardRewards(
            cardName: "Capital One Venture X",
            baseReward: 2.0,
            categoryRewards: [.travel: 10.0],
            suggestedColor: .midnight,
            notes: "10x on hotel/car via Capital One Travel portal. 2x everything else."
        ),
        KnownCardRewards(
            cardName: "Capital One Venture",
            baseReward: 2.0,
            categoryRewards: [.travel: 5.0],
            suggestedColor: .midnight,
            notes: "5x on hotels/cars via Capital One Travel. 2x everything else. Miles."
        ),
        KnownCardRewards(
            cardName: "Capital One Quicksilver",
            baseReward: 1.5,
            categoryRewards: [:],
            suggestedColor: .slate,
            notes: "1.5% flat rate on all purchases. Cash back."
        ),
        KnownCardRewards(
            cardName: "Capital One Savor",
            baseReward: 1.0,
            categoryRewards: [.dining: 4.0, .entertainment: 4.0, .streaming: 4.0, .groceries: 3.0],
            suggestedColor: .crimson,
            notes: "4% dining, entertainment, streaming. 3% groceries. Cash back."
        ),
        KnownCardRewards(
            cardName: "Capital One SavorOne",
            baseReward: 1.0,
            categoryRewards: [.dining: 3.0, .entertainment: 3.0, .streaming: 3.0, .groceries: 3.0],
            suggestedColor: .crimson,
            notes: "3% dining, entertainment, streaming, groceries. Cash back."
        ),

        // ──────────────────────────────────────────────
        // MARK: Discover
        // ──────────────────────────────────────────────

        KnownCardRewards(
            cardName: "Discover it Cash Back",
            baseReward: 1.0,
            categoryRewards: [:],
            suggestedColor: .slate,
            notes: "5% rotating quarterly categories (up to $1,500). Check current quarter and enter manually."
        ),
        KnownCardRewards(
            cardName: "Discover it Miles",
            baseReward: 1.5,
            categoryRewards: [:],
            suggestedColor: .slate,
            notes: "1.5x flat rate on all purchases. Miles."
        ),
        KnownCardRewards(
            cardName: "Discover it Chrome",
            baseReward: 1.0,
            categoryRewards: [.dining: 2.0, .gas: 2.0],
            suggestedColor: .slate,
            notes: "2% dining and gas (up to $1,000/quarter combined). Cash back."
        ),

        // ──────────────────────────────────────────────
        // MARK: Wells Fargo
        // ──────────────────────────────────────────────

        KnownCardRewards(
            cardName: "Wells Fargo Active Cash",
            baseReward: 2.0,
            categoryRewards: [:],
            suggestedColor: .crimson,
            notes: "2% flat rate on all purchases. Cash back."
        ),
        KnownCardRewards(
            cardName: "Wells Fargo Autograph",
            baseReward: 1.0,
            categoryRewards: [.dining: 3.0, .travel: 3.0, .gas: 3.0, .transit: 3.0, .streaming: 3.0, .entertainment: 3.0],
            suggestedColor: .crimson,
            notes: "3x on six popular categories. Points."
        ),

        // ──────────────────────────────────────────────
        // MARK: Bank of America
        // ──────────────────────────────────────────────

        KnownCardRewards(
            cardName: "Bank of America Customized Cash",
            baseReward: 1.0,
            categoryRewards: [.onlineShopping: 2.0],
            suggestedColor: .crimson,
            notes: "3% on a chosen category (set in app), 2% groceries/wholesale. Enter your chosen category manually."
        ),
        KnownCardRewards(
            cardName: "Bank of America Premium Rewards",
            baseReward: 1.5,
            categoryRewards: [.dining: 2.0, .travel: 2.0],
            suggestedColor: .midnight,
            notes: "2% travel and dining. 1.5% everything else. Points."
        ),

        // ──────────────────────────────────────────────
        // MARK: US Bank
        // ──────────────────────────────────────────────

        KnownCardRewards(
            cardName: "US Bank Cash+",
            baseReward: 1.0,
            categoryRewards: [:],
            suggestedColor: .ocean,
            notes: "5% on two chosen categories (up to $2K/quarter). 2% on one category. Enter manually."
        ),
        KnownCardRewards(
            cardName: "US Bank Altitude Connect",
            baseReward: 1.0,
            categoryRewards: [.travel: 4.0, .dining: 2.0, .gas: 2.0, .streaming: 2.0, .groceries: 2.0],
            suggestedColor: .midnight,
            notes: "4x travel. 2x dining, gas, streaming, groceries."
        ),
        KnownCardRewards(
            cardName: "US Bank Altitude Reserve",
            baseReward: 1.0,
            categoryRewards: [.travel: 3.0, .dining: 3.0],
            suggestedColor: .midnight,
            notes: "3x travel and mobile wallet purchases (dining often codes here). Points."
        ),

        // ──────────────────────────────────────────────
        // MARK: Other
        // ──────────────────────────────────────────────

        KnownCardRewards(
            cardName: "Apple Card",
            baseReward: 1.0,
            categoryRewards: [.onlineShopping: 3.0, .dining: 2.0, .transit: 2.0, .entertainment: 2.0, .gas: 2.0, .groceries: 2.0],
            suggestedColor: .slate,
            notes: "3% at Apple and select merchants (Uber, T-Mobile, Nike, etc). 2% via Apple Pay."
        ),
        KnownCardRewards(
            cardName: "Bilt Mastercard",
            baseReward: 1.0,
            categoryRewards: [.dining: 3.0, .travel: 2.0, .transit: 2.0],
            suggestedColor: .onyx,
            notes: "Also earns 1x on rent (up to $100K/yr) with no fees. Points."
        ),
        KnownCardRewards(
            cardName: "PayPal Cashback Mastercard",
            baseReward: 2.0,
            categoryRewards: [:],
            suggestedColor: .ocean,
            notes: "2% flat on all purchases. 3% at PayPal checkout."
        ),
    ]
}
