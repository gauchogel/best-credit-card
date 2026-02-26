//
//  CardsListView.swift
//  Best Credit Card
//

import SwiftUI

// MARK: - Cards List

struct CardsListView: View {
    @Environment(CardStore.self) private var store
    @State private var showingAddCard = false
    @State private var showingScanCard = false

    var body: some View {
        NavigationStack {
            Group {
                if store.cards.isEmpty {
                    emptyState
                } else {
                    cardList
                }
            }
            .navigationTitle("My Cards")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showingAddCard = true
                        } label: {
                            Label("Add Manually", systemImage: "pencil")
                        }
                        Button {
                            showingScanCard = true
                        } label: {
                            Label("Import from Screenshot", systemImage: "photo.on.rectangle")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingAddCard) {
                AddEditCardView()
            }
            .sheet(isPresented: $showingScanCard) {
                ScanCardView()
            }
        }
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("No Cards Added")
                .font(.title2.weight(.semibold))

            Text("Add your credit cards to get personalised reward recommendations.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                showingAddCard = true
            } label: {
                Label("Add Manually", systemImage: "plus")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }

            Button {
                showingScanCard = true
            } label: {
                Label("Import from Screenshot", systemImage: "photo.on.rectangle")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray5))
                    .foregroundStyle(.primary)
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: Card list

    private var cardList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(store.cards) { card in
                    CardRowView(card: card)
                }
            }
            .padding()
        }
    }
}

// MARK: - Card Row

struct CardRowView: View {
    @Environment(CardStore.self) private var store
    let card: CreditCard
    @State private var showingEdit = false
    @State private var showingDeleteConfirm = false

    var body: some View {
        Button {
            showingEdit = true
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                CardVisualView(card: card)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(card.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(subtitleText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding()
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingEdit) {
            AddEditCardView(card: card)
        }
        .contextMenu {
            Button(role: .destructive) {
                showingDeleteConfirm = true
            } label: {
                Label("Delete Card", systemImage: "trash")
            }
        }
        .confirmationDialog(
            "Delete \(card.name)?",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let index = store.cards.firstIndex(where: { $0.id == card.id }) {
                    store.deleteCards(at: IndexSet([index]))
                }
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    private var subtitleText: String {
        let bonusCount = card.rewards.count
        let vendorCount = card.vendorBonuses.count
        let base = String(format: "Base: %.1f%%", card.baseReward)
        var parts = [base]
        if bonusCount > 0 {
            let plural = bonusCount == 1 ? "bonus category" : "bonus categories"
            parts.append("\(bonusCount) \(plural)")
        }
        if vendorCount > 0 {
            let plural = vendorCount == 1 ? "vendor bonus" : "vendor bonuses"
            parts.append("\(vendorCount) \(plural)")
        }
        return parts.joined(separator: " · ")
    }
}
