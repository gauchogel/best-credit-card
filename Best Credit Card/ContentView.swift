//
//  ContentView.swift
//  Best Credit Card
//

import SwiftUI

struct ContentView: View {
    @State private var store = CardStore()
    @State private var locationManager = LocationManager()

    var body: some View {
        TabView {
            NearbyView()
                .tabItem {
                    Label("Nearby", systemImage: "mappin.and.ellipse")
                }

            CardsListView()
                .tabItem {
                    Label("My Cards", systemImage: "creditcard.fill")
                }

            RecommendView()
                .tabItem {
                    Label("Find Best Card", systemImage: "star.fill")
                }
        }
        .environment(store)
        .environment(locationManager)
    }
}

#Preview {
    ContentView()
}
