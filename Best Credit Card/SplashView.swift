//
//  SplashView.swift
//  Best Credit Card
//

import SwiftUI

struct SplashView: View {
    @State private var cardOffset: CGFloat = 80
    @State private var cardOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Background — warm cream matching the app icon
            Color(red: 0.94, green: 0.92, blue: 0.89)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                // Card + wallet icon (mirrors the app icon design)
                ZStack {
                    // Wallet body
                    RoundedRectangle(cornerRadius: 22)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.18, green: 0.18, blue: 0.20),
                                    Color(red: 0.11, green: 0.11, blue: 0.13)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 130, height: 90)
                        .offset(y: 20)

                    // Gold card emerging from wallet
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.94, green: 0.75, blue: 0.25),
                                    Color(red: 0.80, green: 0.56, blue: 0.09),
                                    Color(red: 0.87, green: 0.65, blue: 0.16)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 65)
                        .rotationEffect(.degrees(-12))
                        .offset(y: cardOffset)
                        .opacity(cardOpacity)
                        .shadow(color: .black.opacity(0.2), radius: 10, y: 6)

                    // Chip on the card
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(red: 0.72, green: 0.49, blue: 0.09))
                        .frame(width: 18, height: 14)
                        .rotationEffect(.degrees(-12))
                        .offset(x: -22, y: cardOffset - 8)
                        .opacity(cardOpacity)
                }
                .scaleEffect(pulseScale)

                // App title
                VStack(spacing: 8) {
                    Text("Best Credit Card")
                        .font(.title.weight(.bold))
                        .foregroundStyle(Color(red: 0.18, green: 0.18, blue: 0.20))
                        .opacity(titleOpacity)

                    Text("Finding merchants nearby…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .opacity(subtitleOpacity)
                }

                Spacer()

                // Loading indicator
                ProgressView()
                    .tint(Color(red: 0.80, green: 0.56, blue: 0.09))
                    .scaleEffect(1.2)
                    .opacity(subtitleOpacity)
                    .padding(.bottom, 60)
            }
        }
        .onAppear {
            // Card slides up and fades in
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                cardOffset = -10
                cardOpacity = 1
            }

            // Title fades in
            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                titleOpacity = 1
            }

            // Subtitle + loader fade in
            withAnimation(.easeOut(duration: 0.5).delay(0.7)) {
                subtitleOpacity = 1
            }

            // Subtle pulse loop
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true).delay(1.0)) {
                pulseScale = 1.04
            }
        }
    }
}

#Preview {
    SplashView()
}
