//
//  MerchantLookupView.swift
//  Best Credit Card
//

import SwiftUI

/// Embedded in RecommendView's "By Merchant" mode.
/// Search by merchant name to find the best card to use.
struct MerchantLookupView: View {
    @Environment(CardStore.self) private var store

    @State private var searchText = ""
    @State private var resolvedCategory: RewardCategory?
    @State private var resolvedLabel = ""
    @State private var searchResults: [MerchantEntry] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            searchSection

            if let category = resolvedCategory {
                resolvedBadge(category: category)
                rankedCardsSection(category: category)
            } else {
                placeholderView
            }
        }
    }

    // MARK: - Merchant name search

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Search by merchant")
                .font(.headline)

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("e.g. Chipotle, Starbucks, Costco…", text: $searchText)
                    .autocorrectionDisabled()
                    .onChange(of: searchText) { _, query in
                        searchResults = MCCDatabase.searchMerchants(query: query)
                        if resolvedCategory != nil {
                            resolvedCategory = nil
                            resolvedLabel = ""
                        }
                    }
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        searchResults = []
                        resolvedCategory = nil
                        resolvedLabel = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Results list (max 8 shown)
            if !searchResults.isEmpty && resolvedCategory == nil {
                VStack(spacing: 0) {
                    ForEach(searchResults.prefix(8)) { merchant in
                        Button {
                            selectMerchant(merchant)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: merchant.category.icon)
                                    .foregroundStyle(.blue)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(merchant.name)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.primary)
                                    Text(merchant.category.rawValue)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 4)
                        }
                        if merchant.id != searchResults.prefix(8).last?.id {
                            Divider()
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Resolved category badge

    private func resolvedBadge(category: RewardCategory) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Divider()
            HStack(spacing: 10) {
                Image(systemName: category.icon)
                    .font(.title3)
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 1) {
                    Text(resolvedLabel)
                        .font(.subheadline.weight(.medium))
                    Text("Category: **\(category.rawValue)**")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    resolvedCategory = nil
                    resolvedLabel = ""
                    searchText = ""
                    searchResults = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color.blue.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Ranked cards

    @ViewBuilder
    private func rankedCardsSection(category: RewardCategory) -> some View {
        let ranked = store.rankedCards(for: category, merchantName: resolvedLabel)

        VStack(alignment: .leading, spacing: 14) {
            Label("Best cards for \(resolvedLabel.isEmpty ? category.rawValue : resolvedLabel)",
                  systemImage: category.icon)
                .font(.headline)

            if ranked.isEmpty {
                Text("Add cards to see recommendations.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(ranked.enumerated()), id: \.element.card.id) { index, item in
                    CardRecommendationRow(
                        card: item.card,
                        rate: item.rate,
                        rank: index + 1,
                        isBest: index == 0,
                        source: item.source
                    )
                }
            }
        }
    }

    // MARK: - Placeholder

    private var placeholderView: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "building.columns.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("Search a merchant to see your best card")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 16)
            Spacer()
        }
    }

    // MARK: - Actions

    private func selectMerchant(_ merchant: MerchantEntry) {
        searchText = merchant.name
        resolvedCategory = merchant.category
        resolvedLabel = merchant.name
        searchResults = []
    }
}
