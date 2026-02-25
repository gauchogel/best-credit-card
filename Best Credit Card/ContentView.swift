//
//  ContentView.swift
//  Best Credit Card
//

import SwiftUI

struct ContentView: View {
    @State private var store = CardStore()

    var body: some View {
        TabView {
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
    }
}

#Preview {
    ContentView()
}
