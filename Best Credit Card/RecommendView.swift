//
//  RecommendView.swift
//  Best Credit Card
//

import SwiftUI

// MARK: - Recommend View

struct RecommendView: View {
    @Environment(CardStore.self) private var store
    @State private var selectedCategory: RewardCategory?
    @State private var lookupMode: LookupMode = .category

    enum LookupMode: String, CaseIterable {
        case category = "By Category"
        case merchant = "By Merchant"
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.cards.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            Picker("Lookup Mode", selection: $lookupMode) {
                                ForEach(LookupMode.allCases, id: \.self) { mode in
                                    Text(mode.rawValue).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)

                            switch lookupMode {
                            case .category:
                                categoryGrid
                                if let category = selectedCategory {
                                    resultsSection(for: category)
                                } else {
                                    placeholderPrompt
                                }
                            case .merchant:
                                MerchantLookupView()
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Find Best Card")
        }
    }

    // MARK: - Sections

    private var categoryGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Where are you shopping?")
                .font(.headline)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3),
                spacing: 12
            ) {
                ForEach(RewardCategory.allCases) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedCategory = (selectedCategory == category) ? nil : category
                        }
                    }
                }
            }
        }
    }

    private var placeholderPrompt: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "hand.tap.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("Tap a category above\nto see your best card")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 16)
            Spacer()
        }
    }

    @ViewBuilder
    private func resultsSection(for category: RewardCategory) -> some View {
        let ranked = store.rankedCards(for: category)

        VStack(alignment: .leading, spacing: 16) {
            Divider()

            Label("Best for \(category.rawValue)", systemImage: category.icon)
                .font(.headline)

            ForEach(Array(ranked.enumerated()), id: \.element.card.id) { index, item in
                CardRecommendationRow(
                    card: item.card,
                    rate: item.rate,
                    rank: index + 1,
                    isBest: index == 0
                )
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.fill")
                .font(.system(size: 64))
                .foregroundStyle(.yellow)
            Text("Add Cards First")
                .font(.title2.weight(.semibold))
            Text("Head over to My Cards and add your credit cards to get recommendations.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .navigationTitle("Find Best Card")
    }
}

// MARK: - Category Button

struct CategoryButton: View {
    let category: RewardCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .frame(height: 28)
                Text(category.rawValue)
                    .font(.caption.weight(.medium))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Card Recommendation Row

struct CardRecommendationRow: View {
    let card: CreditCard
    let rate: Double
    let rank: Int
    let isBest: Bool

    var body: some View {
        HStack(spacing: 14) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(isBest ? Color.yellow.opacity(0.25) : Color(.systemGray5))
                    .frame(width: 38, height: 38)
                if isBest {
                    Image(systemName: "star.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.orange)
                } else {
                    Text("\(rank)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
            }

            // Compact card thumbnail
            CardVisualView(card: card, compact: true)
                .frame(width: 72)

            // Card name / last four
            VStack(alignment: .leading, spacing: 2) {
                Text(card.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                if !card.lastFour.isEmpty {
                    Text("···· \(card.lastFour)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Reward rate
            VStack(alignment: .trailing, spacing: 0) {
                Text(String(format: "%.1f%%", rate))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(isBest ? .green : .primary)
                Text("back")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(isBest ? Color.green.opacity(0.07) : Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isBest ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1.5)
        )
    }
}
