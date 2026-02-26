//
//  Best_Credit_CardApp.swift
//  Best Credit Card
//
//  Created by Scott Vogelgesang on 2/25/26.
//

import SwiftUI
import GooglePlaces

// TODO: Replace with your Google Places API key.
// 1. Get a key at https://console.cloud.google.com — enable "Places API (New)".
// 2. Paste it below (or load from a config file / environment variable).
private let googlePlacesAPIKey = "YOUR_GOOGLE_PLACES_API_KEY"

@main
struct Best_Credit_CardApp: App {
    init() {
        GMSPlacesClient.provideAPIKey(googlePlacesAPIKey)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
