//
//  NearbyService.swift
//  Best Credit Card
//

import Foundation
import CoreLocation

// API key is defined in Secrets.swift (gitignored).
// Copy Secrets.swift.example → Secrets.swift and add your key.

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

    /// Fetches nearby merchants using the Google Places REST API, sorted by distance.
    static func fetch(near location: CLLocation) async throws -> [NearbyMerchant] {
        let url = URL(string: "https://places.googleapis.com/v1/places:searchNearby")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(googlePlacesAPIKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue(
            "places.id,places.displayName,places.formattedAddress,places.types,places.location",
            forHTTPHeaderField: "X-Goog-FieldMask"
        )

        let body = SearchRequest(
            includedTypes: prioritySearchTypes,
            maxResultCount: 20,
            locationRestriction: .init(circle: .init(
                center: .init(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                ),
                radius: searchRadius
            ))
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let http = response as? HTTPURLResponse
            let body = String(data: data, encoding: .utf8) ?? "no body"
            print("Places API error \(http?.statusCode ?? -1): \(body)")
            throw NSError(
                domain: "NearbyService",
                code: http?.statusCode ?? -1,
                userInfo: [NSLocalizedDescriptionKey: "Places API error \(http?.statusCode ?? -1): \(body)"]
            )
        }

        let decoded = try JSONDecoder().decode(SearchResponse.self, from: data)

        return (decoded.places ?? []).compactMap { place in
            guard let id = place.id,
                  let name = place.displayName?.text else { return nil }

            let types = place.types ?? []
            let category = types.lazy
                .compactMap { googlePlaceTypeToRewardCategory[$0] }
                .first ?? .other

            var distance: CLLocationDistance = 0
            var coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
            if let loc = place.location {
                coordinate = CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
                distance = location.distance(from: CLLocation(latitude: loc.latitude, longitude: loc.longitude))
            }

            return NearbyMerchant(
                id: id,
                name: name,
                address: place.formattedAddress ?? "",
                distance: distance,
                category: category,
                googleTypes: types,
                coordinate: coordinate
            )
        }
        .sorted { $0.distance < $1.distance }
    }

    // MARK: - REST API Codable Types

    private struct SearchRequest: Encodable {
        let includedTypes: [String]
        let maxResultCount: Int
        let locationRestriction: LocationRestriction

        struct LocationRestriction: Encodable {
            let circle: Circle

            struct Circle: Encodable {
                let center: Center
                let radius: Double

                struct Center: Encodable {
                    let latitude: Double
                    let longitude: Double
                }
            }
        }
    }

    private struct SearchResponse: Decodable {
        let places: [Place]?

        struct Place: Decodable {
            let id: String?
            let displayName: DisplayName?
            let formattedAddress: String?
            let types: [String]?
            let location: Location?

            struct DisplayName: Decodable {
                let text: String?
            }

            struct Location: Decodable {
                let latitude: Double
                let longitude: Double
            }
        }
    }

    // MARK: - Priority Types for Search

    /// Types sent to the Places API to focus results on reward-relevant merchants.
    private static let prioritySearchTypes: [String] = [
        // Dining
        "restaurant", "cafe", "bakery", "bar",
        // Grocery
        "supermarket", "convenience_store",
        // Gas
        "gas_station", "electric_vehicle_charging_station",
        // Hotels
        "lodging",
        // Drug Stores
        "pharmacy",
        // Entertainment
        "movie_theater", "amusement_park",
    ]

    // MARK: - Google Place Type → RewardCategory

    /// Maps Google Places `types` strings to the app's RewardCategory.
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
