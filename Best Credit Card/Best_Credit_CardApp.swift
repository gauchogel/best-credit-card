//
//  Best_Credit_CardApp.swift
//  Best Credit Card
//
//  Created by Scott Vogelgesang on 2/25/26.
//

import SwiftUI

@main
struct Best_Credit_CardApp: App {
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .opacity(showSplash ? 0 : 1)

                if showSplash {
                    SplashView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: showSplash)
            .task {
                // Show splash for a minimum of 2 seconds, giving
                // location services time to get an initial fix.
                try? await Task.sleep(for: .seconds(2))
                showSplash = false
            }
        }
    }
}
