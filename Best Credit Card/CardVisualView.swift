//
//  CardVisualView.swift
//  Best Credit Card
//

import SwiftUI

/// A credit-card-shaped visual that renders in full or compact mode.
struct CardVisualView: View {
    let card: CreditCard
    var compact: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: compact ? 10 : 16)
                .fill(card.cardColor.gradient)

            if compact {
                compactContent
            } else {
                fullContent
            }
        }
        // Standard credit card aspect ratio (85.6 mm × 53.98 mm)
        .aspectRatio(1.586, contentMode: .fit)
        .shadow(
            color: card.cardColor.startColor.opacity(0.45),
            radius: compact ? 4 : 10,
            x: 0,
            y: compact ? 3 : 6
        )
    }

    // MARK: - Compact layout (thumbnail)

    private var compactContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "creditcard.fill")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
            }
            Spacer()
            Text(card.name)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
            if !card.lastFour.isEmpty {
                Text("···· \(card.lastFour)")
                    .font(.system(size: 8))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding(8)
    }

    // MARK: - Full layout

    private var fullContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                // Chip
                RoundedRectangle(cornerRadius: 4)
                    .fill(.white.opacity(0.25))
                    .frame(width: 38, height: 28)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(.white.opacity(0.45), lineWidth: 1)
                    )
                Spacer()
                Image(systemName: "wave.3.right")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            if !card.lastFour.isEmpty {
                Text("···· ···· ···· \(card.lastFour)")
                    .font(.system(.callout, design: .monospaced, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.bottom, 6)
            }

            Text(card.name)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(20)
    }
}
