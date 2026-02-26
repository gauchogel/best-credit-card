//
//  NearbyService.swift
//  Best Credit Card
//

import Foundation
import MapKit
import CoreLocation

// MARK: - Nearby Merchant

struct NearbyMerchant: Identifiable {
    let id: String
    let name: String
    let address: String
    let distance: CLLocationDistance  // meters
    let category: RewardCategory
    let coordinate: CLLocationCoordinate2D

    var distanceText: String {
        let feet = distance * 3.28084
        if feet < 1000 {
            return String(format: "%.0f ft", feet)
        }
        let miles = distance / 1609.34
        return String(format: "%.1f mi", miles)

    }
}

// MARK: - Nearby Service

struct NearbyService {

    /// Search radius in meters (0.25 miles ≈ 402 m)
    private static let searchRadius: CLLocationDistance = 402

    /// Fetches nearby merchants within 0.25 miles, sorted by distance.
    static func fetch(near location: CLLocation) async throws -> [NearbyMerchant] {
        let region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: searchRadius * 2,
            longitudinalMeters: searchRadius * 2
        )

        var allMerchants: [NearbyMerchant] = []

        // Search each POI category we care about
        for (poiCategory, rewardCategory) in poiMapping {
            let request = MKLocalPointsOfInterestRequest(center: location.coordinate, radius: searchRadius)
            request.pointOfInterestFilter = MKPointOfInterestFilter(including: [poiCategory])

            let search = MKLocalSearch(request: request)
            do {
                let response = try await search.start()
                for item in response.mapItems {
                    let merchant = NearbyMerchant(
                        id: "\(item.name ?? "")_\(item.placemark.coordinate.latitude)_\(item.placemark.coordinate.longitude)",
                        name: item.name ?? "Unknown",
                        address: formatAddress(item.placemark),
                        distance: location.distance(from: CLLocation(
                            latitude: item.placemark.coordinate.latitude,
                            longitude: item.placemark.coordinate.longitude
                        )),
                        category: rewardCategory,
                        coordinate: item.placemark.coordinate
                    )
                    allMerchants.append(merchant)
                }
            } catch {
                // Skip this category on failure, continue with others
                continue
            }
        }

        // Deduplicate by name + rough location
        var seen = Set<String>()
        let unique = allMerchants.filter { merchant in
            let key = "\(merchant.name.lowercased())_\(Int(merchant.coordinate.latitude * 1000))_\(Int(merchant.coordinate.longitude * 1000))"
            return seen.insert(key).inserted
        }

        // Sort by distance
        return unique.sorted { $0.distance < $1.distance }
    }

    // MARK: - POI → RewardCategory Mapping

    private static let poiMapping: [(MKPointOfInterestCategory, RewardCategory)] = [
        (.restaurant, .dining),
        (.cafe, .dining),
        (.bakery, .dining),
        (.brewery, .dining),
        (.foodMarket, .groceries),
        (.gasStation, .gas),
        (.evCharger, .gas),
        (.hotel, .travel),
        (.airport, .travel),
        (.carRental, .travel),
        (.movieTheater, .entertainment),
        (.theater, .entertainment),
        (.amusementPark, .entertainment),
        (.nightlife, .entertainment),
        (.stadium, .entertainment),
        (.zoo, .entertainment),
        (.pharmacy, .drugstores),
        (.store, .other),
        (.parking, .transit),
    ]

    // MARK: - Helpers

    private static func formatAddress(_ placemark: MKPlacemark) -> String {
        var parts: [String] = []
        if let number = placemark.subThoroughfare { parts.append(number) }
        if let street = placemark.thoroughfare { parts.append(street) }
        if parts.isEmpty, let city = placemark.locality { parts.append(city) }
        return parts.joined(separator: " ")
    }
}
