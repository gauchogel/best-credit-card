//
//  NearbyService.swift
//  Best Credit Card
//

import Foundation
import CoreLocation
import GooglePlaces

// MARK: - Nearby Merchant

struct NearbyMerchant: Identifiable {
    let id: String
    let name: String
    let address: String
    let distance: CLLocationDistance  // meters
    let category: RewardCategory
    let googleTypes: [String]         // raw Google Places type strings
    let coordinate: CLLocationCoordinate2D

    var distanceText: String {
        let feet = distance * 3.28084
        if feet < 1000 {
            return String(format: "%.0f ft", feet)
        }
        return String(format: "%.1f mi", distance / 1609.34)
    }
}

// MARK: - Nearby Service

struct NearbyService {

    /// Search radius in meters (≈ 0.3 miles)
    static let searchRadius: Double = 500

    /// Fetches nearby merchants using Google Places, sorted by distance.
    static func fetch(near location: CLLocation) async throws -> [NearbyMerchant] {
        try await withCheckedThrowingContinuation { continuation in
            let client = GMSPlacesClient.shared()

            let request = GMSPlaceSearchNearbyRequest(
                locationRestriction: GMSPlaceCircularLocationOption(
                    location.coordinate,
                    searchRadius
                ),
                placeProperties: GMSPlaceProperty.allProperties
            )
            request.includedTypes = prioritySearchTypes
            request.maxResultCount = 20

            let fields: GMSPlaceField = [.name, .formattedAddress, .placeID, .types, .coordinate]
            client.searchNearby(with: request, fields: fields) { results, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let merchants: [NearbyMerchant] = (results ?? []).compactMap { place in
                    guard let name = place.name, let placeID = place.placeID else { return nil }

                    let types = place.types ?? []
                    let category = types.lazy
                        .compactMap { googlePlaceTypeToRewardCategory[$0] }
                        .first ?? .other

                    let coord = place.coordinate
                    let distance = CLLocationCoordinate2DIsValid(coord)
                        ? location.distance(from: CLLocation(latitude: coord.latitude, longitude: coord.longitude))
                        : 0

                    return NearbyMerchant(
                        id: placeID,
                        name: name,
                        address: place.formattedAddress ?? "",
                        distance: distance,
                        category: category,
                        googleTypes: types,
                        coordinate: coord
                    )
                }
                .sorted { $0.distance < $1.distance }

                continuation.resume(returning: merchants)
            }
        }
    }

    // MARK: - Priority Types for Search

    /// Types sent to the Places API to focus results on reward-relevant merchants.
    /// Google returns places matching ANY of these types.
    private static let prioritySearchTypes: [String] = [
        // Dining
        "restaurant", "fast_food_restaurant", "cafe", "bakery", "bar",
        "coffee_shop", "pizza_restaurant", "sandwich_shop",
        // Grocery
        "supermarket", "grocery_or_supermarket",
        // Gas
        "gas_station", "electric_vehicle_charging_station",
        // Hotels
        "lodging", "hotel",
        // Drug Stores
        "pharmacy", "drugstore",
        // Entertainment
        "movie_theater", "amusement_park",
        // Wholesale
        "warehouse_store",
        // Convenience
        "convenience_store",
        // Transit
        "bus_station", "train_station", "subway_station",
    ]

    // MARK: - Google Place Type → RewardCategory

    /// Maps Google Places `types` strings to the app's RewardCategory.
    /// First match in the place's types array wins, so order matters at call site.
    static let googlePlaceTypeToRewardCategory: [String: RewardCategory] = [

        // ── Dining ────────────────────────────────────────────────────────────
        "restaurant":               .dining,
        "food":                     .dining,
        "meal_takeaway":            .dining,
        "meal_delivery":            .dining,
        "cafe":                     .dining,
        "bakery":                   .dining,
        "bar":                      .dining,
        "night_club":               .dining,
        "fast_food_restaurant":     .dining,
        "coffee_shop":              .dining,
        "sandwich_shop":            .dining,
        "pizza_restaurant":         .dining,
        "sushi_restaurant":         .dining,
        "steak_house":              .dining,
        "seafood_restaurant":       .dining,
        "mexican_restaurant":       .dining,
        "chinese_restaurant":       .dining,
        "thai_restaurant":          .dining,
        "indian_restaurant":        .dining,
        "italian_restaurant":       .dining,
        "american_restaurant":      .dining,
        "ramen_restaurant":         .dining,
        "ice_cream_shop":           .dining,
        "juice_shop":               .dining,
        "wine_bar":                 .dining,
        "cocktail_bar":             .dining,
        "sports_bar":               .dining,
        "brunch_restaurant":        .dining,

        // ── Grocery ───────────────────────────────────────────────────────────
        "supermarket":                  .groceries,
        "grocery_or_supermarket":       .groceries,
        "health_food_store":            .groceries,
        "market":                       .groceries,
        "convenience_store":            .groceries,
        "fruit_and_vegetable_store":    .groceries,
        "butcher_shop":                 .groceries,
        "seafood_market":               .groceries,

        // ── Gas & EV ──────────────────────────────────────────────────────────
        "gas_station":                          .gas,
        "electric_vehicle_charging_station":    .gas,

        // ── Travel ────────────────────────────────────────────────────────────
        "airport":              .travel,
        "travel_agency":        .travel,
        "car_rental":           .travel,
        "campground":           .travel,
        "tourist_attraction":   .travel,
        "lodging":              .travel,
        "hotel":                .travel,
        "motel":                .travel,
        "extended_stay_hotel":  .travel,
        "bed_and_breakfast":    .travel,
        "resort_hotel":         .travel,
        "hostel":               .travel,
        "cottage":              .travel,

        // ── Transit ───────────────────────────────────────────────────────────
        "taxi_stand":           .transit,
        "bus_station":          .transit,
        "train_station":        .transit,
        "subway_station":       .transit,
        "transit_station":      .transit,
        "light_rail_station":   .transit,
        "ferry_terminal":       .transit,
        "parking":              .transit,

        // ── Wholesale Clubs ───────────────────────────────────────────────────
        "warehouse_store":  .wholesale,

        // ── Drug Stores ───────────────────────────────────────────────────────
        "pharmacy":     .drugstores,
        "drugstore":    .drugstores,

        // ── Entertainment ─────────────────────────────────────────────────────
        "movie_theater":            .entertainment,
        "amusement_park":           .entertainment,
        "bowling_alley":            .entertainment,
        "stadium":                  .entertainment,
        "performing_arts_theater":  .entertainment,
        "comedy_club":              .entertainment,
        "casino":                   .entertainment,
        "golf_course":              .entertainment,
        "gym":                      .entertainment,
        "fitness_center":           .entertainment,
        "spa":                      .entertainment,
    ]
}
