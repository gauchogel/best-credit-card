//
//  MCCDatabase.swift
//  Best Credit Card
//

import Foundation

// MARK: - Merchant Entry

struct MerchantEntry: Identifiable {
    let name: String
    let mccCode: Int
    let category: RewardCategory

    var id: String { "\(name)-\(mccCode)" }
}

// MARK: - MCC Database

struct MCCDatabase {

    // MARK: MCC → RewardCategory

    /// Returns the RewardCategory for a given MCC code, or nil if unknown.
    static func category(for mccCode: Int) -> RewardCategory? {
        // Airlines and hotels: 3000-3999
        if (3000...3999).contains(mccCode) { return .travel }
        return mccTable[mccCode]
    }

    /// Search merchants by name (case-insensitive substring match).
    static func searchMerchants(query: String) -> [MerchantEntry] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard q.count >= 1 else { return [] }
        return merchants
            .filter { $0.name.lowercased().contains(q) }
            .sorted { a, b in
                let aPrefix = a.name.lowercased().hasPrefix(q)
                let bPrefix = b.name.lowercased().hasPrefix(q)
                if aPrefix != bPrefix { return aPrefix }
                return a.name < b.name
            }
    }

    // MARK: - MCC Table

    private static let mccTable: [Int: RewardCategory] = [
        // Dining
        5811: .dining,      // Caterers
        5812: .dining,      // Eating places / restaurants
        5813: .dining,      // Bars / taverns / nightclubs
        5814: .dining,      // Fast food restaurants

        // Groceries
        5411: .groceries,   // Grocery stores / supermarkets
        5422: .groceries,   // Freezer / meat lockers
        5441: .groceries,   // Candy / nut / confection stores
        5451: .groceries,   // Dairy products stores
        5462: .groceries,   // Bakeries
        5499: .groceries,   // Misc food stores

        // Gas & EV Charging
        5541: .gas,         // Service stations (with or without ancillary)
        5542: .gas,         // Fuel dispensers – automated
        5983: .gas,         // Fuel dealers (non-automotive)

        // Travel
        4511: .travel,      // Airlines / air carriers
        4722: .travel,      // Travel agencies / tour operators
        7011: .travel,      // Hotels / motels / resorts
        7012: .travel,      // Timeshares
        7033: .travel,      // Campgrounds / trailer parks
        7512: .travel,      // Car rentals
        7513: .travel,      // Truck / utility trailer rentals

        // Streaming
        4899: .streaming,   // Cable / pay TV / streaming services

        // Online Shopping
        5942: .onlineShopping, // Book stores (Amazon's common MCC)
        5691: .onlineShopping, // Men's & women's clothing stores (online)
        5311: .onlineShopping, // Department stores (Walmart.com, Target.com)

        // Wholesale Clubs
        5300: .wholesale,   // Wholesale clubs

        // Drug Stores
        5912: .drugstores,  // Drug stores and pharmacies

        // Entertainment
        7832: .entertainment, // Motion picture theaters
        7922: .entertainment, // Theatrical producers
        7929: .entertainment, // Bands / orchestras / entertainers
        7941: .entertainment, // Sports clubs / fields / promoters
        7991: .entertainment, // Tourist attractions
        7993: .entertainment, // Video game arcades
        7994: .entertainment, // Video game supplies
        7996: .entertainment, // Amusement parks / circuses
        7998: .entertainment, // Aquariums / dolphinariums / zoos
        7999: .entertainment, // Recreation services (misc)

        // Transit
        4011: .transit,     // Railroads – freight
        4111: .transit,     // Local / suburban commuter transit
        4112: .transit,     // Passenger railways
        4121: .transit,     // Taxicabs / rideshare
        4131: .transit,     // Bus lines
        4784: .transit,     // Tolls / bridge fees
        4789: .transit,     // Transportation services (misc)

        // General retail (maps to "Everything Else")
        5399: .other,       // General merchandise
    ]

    // MARK: - Merchants

    static let merchants: [MerchantEntry] = [

        // ── Dining ──────────────────────────────────
        MerchantEntry(name: "Chipotle", mccCode: 5812, category: .dining),
        MerchantEntry(name: "McDonald's", mccCode: 5814, category: .dining),
        MerchantEntry(name: "Starbucks", mccCode: 5812, category: .dining),
        MerchantEntry(name: "Chick-fil-A", mccCode: 5814, category: .dining),
        MerchantEntry(name: "Subway", mccCode: 5812, category: .dining),
        MerchantEntry(name: "Panera Bread", mccCode: 5812, category: .dining),
        MerchantEntry(name: "Taco Bell", mccCode: 5814, category: .dining),
        MerchantEntry(name: "Wendy's", mccCode: 5814, category: .dining),
        MerchantEntry(name: "Burger King", mccCode: 5814, category: .dining),
        MerchantEntry(name: "Domino's", mccCode: 5812, category: .dining),
        MerchantEntry(name: "Pizza Hut", mccCode: 5812, category: .dining),
        MerchantEntry(name: "Panda Express", mccCode: 5814, category: .dining),
        MerchantEntry(name: "Olive Garden", mccCode: 5812, category: .dining),
        MerchantEntry(name: "Applebee's", mccCode: 5812, category: .dining),
        MerchantEntry(name: "Chili's", mccCode: 5812, category: .dining),
        MerchantEntry(name: "Texas Roadhouse", mccCode: 5812, category: .dining),
        MerchantEntry(name: "Outback Steakhouse", mccCode: 5812, category: .dining),
        MerchantEntry(name: "The Cheesecake Factory", mccCode: 5812, category: .dining),
        MerchantEntry(name: "Buffalo Wild Wings", mccCode: 5812, category: .dining),
        MerchantEntry(name: "Cracker Barrel", mccCode: 5812, category: .dining),
        MerchantEntry(name: "Popeyes", mccCode: 5814, category: .dining),
        MerchantEntry(name: "Five Guys", mccCode: 5812, category: .dining),
        MerchantEntry(name: "In-N-Out Burger", mccCode: 5814, category: .dining),
        MerchantEntry(name: "Whataburger", mccCode: 5814, category: .dining),
        MerchantEntry(name: "Dunkin'", mccCode: 5812, category: .dining),
        MerchantEntry(name: "DoorDash", mccCode: 5812, category: .dining),
        MerchantEntry(name: "Uber Eats", mccCode: 5812, category: .dining),
        MerchantEntry(name: "Grubhub", mccCode: 5812, category: .dining),

        // ── Groceries ───────────────────────────────
        MerchantEntry(name: "Walmart Grocery", mccCode: 5411, category: .groceries),
        MerchantEntry(name: "Kroger", mccCode: 5411, category: .groceries),
        MerchantEntry(name: "Whole Foods", mccCode: 5411, category: .groceries),
        MerchantEntry(name: "Trader Joe's", mccCode: 5411, category: .groceries),
        MerchantEntry(name: "Publix", mccCode: 5411, category: .groceries),
        MerchantEntry(name: "Safeway", mccCode: 5411, category: .groceries),
        MerchantEntry(name: "Albertsons", mccCode: 5411, category: .groceries),
        MerchantEntry(name: "H-E-B", mccCode: 5411, category: .groceries),
        MerchantEntry(name: "Aldi", mccCode: 5411, category: .groceries),
        MerchantEntry(name: "Lidl", mccCode: 5411, category: .groceries),
        MerchantEntry(name: "Sprouts Farmers Market", mccCode: 5411, category: .groceries),
        MerchantEntry(name: "Meijer", mccCode: 5411, category: .groceries),
        MerchantEntry(name: "Food Lion", mccCode: 5411, category: .groceries),
        MerchantEntry(name: "WinCo Foods", mccCode: 5411, category: .groceries),
        MerchantEntry(name: "Instacart", mccCode: 5411, category: .groceries),
        MerchantEntry(name: "Target Grocery", mccCode: 5411, category: .groceries),

        // ── Gas & EV Charging ───────────────────────
        MerchantEntry(name: "Shell", mccCode: 5541, category: .gas),
        MerchantEntry(name: "Chevron", mccCode: 5541, category: .gas),
        MerchantEntry(name: "ExxonMobil", mccCode: 5541, category: .gas),
        MerchantEntry(name: "BP", mccCode: 5541, category: .gas),
        MerchantEntry(name: "Costco Gas", mccCode: 5541, category: .gas),
        MerchantEntry(name: "Sam's Club Gas", mccCode: 5541, category: .gas),
        MerchantEntry(name: "Marathon", mccCode: 5541, category: .gas),
        MerchantEntry(name: "Speedway", mccCode: 5541, category: .gas),
        MerchantEntry(name: "Sunoco", mccCode: 5541, category: .gas),
        MerchantEntry(name: "7-Eleven Gas", mccCode: 5541, category: .gas),
        MerchantEntry(name: "Tesla Supercharger", mccCode: 5541, category: .gas),
        MerchantEntry(name: "ChargePoint", mccCode: 5541, category: .gas),

        // ── Travel ──────────────────────────────────
        MerchantEntry(name: "Delta Airlines", mccCode: 3058, category: .travel),
        MerchantEntry(name: "United Airlines", mccCode: 3000, category: .travel),
        MerchantEntry(name: "American Airlines", mccCode: 3001, category: .travel),
        MerchantEntry(name: "Southwest Airlines", mccCode: 3024, category: .travel),
        MerchantEntry(name: "JetBlue", mccCode: 3096, category: .travel),
        MerchantEntry(name: "Spirit Airlines", mccCode: 3256, category: .travel),
        MerchantEntry(name: "Frontier Airlines", mccCode: 3261, category: .travel),
        MerchantEntry(name: "Marriott", mccCode: 3501, category: .travel),
        MerchantEntry(name: "Hilton", mccCode: 3504, category: .travel),
        MerchantEntry(name: "Hyatt", mccCode: 3515, category: .travel),
        MerchantEntry(name: "IHG (Holiday Inn)", mccCode: 3502, category: .travel),
        MerchantEntry(name: "Airbnb", mccCode: 7011, category: .travel),
        MerchantEntry(name: "VRBO", mccCode: 7011, category: .travel),
        MerchantEntry(name: "Enterprise Rent-A-Car", mccCode: 7512, category: .travel),
        MerchantEntry(name: "Hertz", mccCode: 7512, category: .travel),
        MerchantEntry(name: "Expedia", mccCode: 4722, category: .travel),
        MerchantEntry(name: "Booking.com", mccCode: 4722, category: .travel),

        // ── Streaming ───────────────────────────────
        MerchantEntry(name: "Netflix", mccCode: 4899, category: .streaming),
        MerchantEntry(name: "Hulu", mccCode: 4899, category: .streaming),
        MerchantEntry(name: "Disney+", mccCode: 4899, category: .streaming),
        MerchantEntry(name: "HBO Max", mccCode: 4899, category: .streaming),
        MerchantEntry(name: "Spotify", mccCode: 4899, category: .streaming),
        MerchantEntry(name: "Apple TV+", mccCode: 4899, category: .streaming),
        MerchantEntry(name: "YouTube Premium", mccCode: 4899, category: .streaming),
        MerchantEntry(name: "Peacock", mccCode: 4899, category: .streaming),
        MerchantEntry(name: "Paramount+", mccCode: 4899, category: .streaming),
        MerchantEntry(name: "Amazon Prime Video", mccCode: 4899, category: .streaming),
        MerchantEntry(name: "Apple Music", mccCode: 4899, category: .streaming),
        MerchantEntry(name: "SiriusXM", mccCode: 4899, category: .streaming),

        // ── Online Shopping ─────────────────────────
        MerchantEntry(name: "Amazon.com", mccCode: 5942, category: .onlineShopping),
        MerchantEntry(name: "Walmart.com", mccCode: 5311, category: .onlineShopping),
        MerchantEntry(name: "Target.com", mccCode: 5311, category: .onlineShopping),
        MerchantEntry(name: "Best Buy (online)", mccCode: 5311, category: .onlineShopping),
        MerchantEntry(name: "Apple Store (online)", mccCode: 5691, category: .onlineShopping),
        MerchantEntry(name: "eBay", mccCode: 5942, category: .onlineShopping),
        MerchantEntry(name: "Etsy", mccCode: 5942, category: .onlineShopping),

        // ── Wholesale ───────────────────────────────
        MerchantEntry(name: "Costco", mccCode: 5300, category: .wholesale),
        MerchantEntry(name: "Sam's Club", mccCode: 5300, category: .wholesale),
        MerchantEntry(name: "BJ's Wholesale", mccCode: 5300, category: .wholesale),

        // ── Drug Stores ─────────────────────────────
        MerchantEntry(name: "CVS Pharmacy", mccCode: 5912, category: .drugstores),
        MerchantEntry(name: "Walgreens", mccCode: 5912, category: .drugstores),
        MerchantEntry(name: "Rite Aid", mccCode: 5912, category: .drugstores),

        // ── Entertainment ───────────────────────────
        MerchantEntry(name: "AMC Theatres", mccCode: 7832, category: .entertainment),
        MerchantEntry(name: "Regal Cinemas", mccCode: 7832, category: .entertainment),
        MerchantEntry(name: "Cinemark", mccCode: 7832, category: .entertainment),
        MerchantEntry(name: "Dave & Buster's", mccCode: 7993, category: .entertainment),
        MerchantEntry(name: "Topgolf", mccCode: 7941, category: .entertainment),
        MerchantEntry(name: "Six Flags", mccCode: 7996, category: .entertainment),
        MerchantEntry(name: "Disney Parks", mccCode: 7996, category: .entertainment),
        MerchantEntry(name: "Universal Studios", mccCode: 7996, category: .entertainment),
        MerchantEntry(name: "Live Nation / Ticketmaster", mccCode: 7922, category: .entertainment),

        // ── Transit ─────────────────────────────────
        MerchantEntry(name: "Uber (rides)", mccCode: 4121, category: .transit),
        MerchantEntry(name: "Lyft", mccCode: 4121, category: .transit),
        MerchantEntry(name: "NYC MTA / Subway", mccCode: 4111, category: .transit),
        MerchantEntry(name: "Chicago CTA", mccCode: 4111, category: .transit),
        MerchantEntry(name: "BART", mccCode: 4111, category: .transit),
        MerchantEntry(name: "Amtrak", mccCode: 4112, category: .transit),
        MerchantEntry(name: "E-ZPass / Tolls", mccCode: 4784, category: .transit),
    ]
}
