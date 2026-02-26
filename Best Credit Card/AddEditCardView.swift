//
//  AddEditCardView.swift
//  Best Credit Card
//

import SwiftUI

// MARK: - Add / Edit Card

struct AddEditCardView: View {
    @Environment(CardStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let existingCard: CreditCard?

    @State private var name: String
    @State private var lastFour: String
    @State private var selectedColor: CardColor
    @State private var baseReward: Double
    @State private var categoryRewards: [RewardCategory: Double]
    @State private var vendorBonuses: [VendorBonus]

    // Auto-fill
    @State private var suggestions: [KnownCardRewards] = []
    @State private var autoFillNotes: String = ""
    @State private var showAutoFillBanner: Bool = false
    @State private var searchTask: Task<Void, Never>?

    // Delete
    @State private var showingDeleteConfirm = false

    // MARK: Init

    init(card: CreditCard? = nil) {
        existingCard = card
        if let card {
            _name           = State(initialValue: card.name)
            _lastFour       = State(initialValue: card.lastFour)
            _selectedColor  = State(initialValue: card.cardColor)
            _baseReward     = State(initialValue: card.baseReward)
            var rewards: [RewardCategory: Double] = [:]
            for category in RewardCategory.allCases {
                if let value = card.rewards[category.rawValue] {
                    rewards[category] = value
                }
            }
            _categoryRewards = State(initialValue: rewards)
            _vendorBonuses   = State(initialValue: card.vendorBonuses)
        } else {
            _name            = State(initialValue: "")
            _lastFour        = State(initialValue: "")
            _selectedColor   = State(initialValue: .ocean)
            _baseReward      = State(initialValue: 1.0)
            _categoryRewards = State(initialValue: [:])
            _vendorBonuses   = State(initialValue: [])
        }
    }

    init(scannedInfo: ScannedCardInfo) {
        existingCard = nil
        _name        = State(initialValue: scannedInfo.name)
        _lastFour    = State(initialValue: scannedInfo.lastFour)

        if let known = scannedInfo.suggestedRewards {
            _selectedColor      = State(initialValue: known.suggestedColor)
            _baseReward         = State(initialValue: known.baseReward)
            _categoryRewards    = State(initialValue: known.categoryRewards)
            _vendorBonuses      = State(initialValue: known.vendorBonuses)
            _autoFillNotes      = State(initialValue: known.notes)
            _showAutoFillBanner = State(initialValue: true)
        } else {
            _selectedColor   = State(initialValue: .ocean)
            _baseReward      = State(initialValue: 1.0)
            _categoryRewards = State(initialValue: [:])
            _vendorBonuses   = State(initialValue: [])
        }
    }

    // MARK: Helpers

    private var isEditing: Bool { existingCard != nil }
    private var isFormValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    private var previewCard: CreditCard {
        CreditCard(
            name: name.isEmpty ? "Card Name" : name,
            lastFour: lastFour,
            cardColor: selectedColor,
            rewards: Dictionary(
                uniqueKeysWithValues: categoryRewards.map { ($0.key.rawValue, $0.value) }
            ),
            baseReward: baseReward,
            vendorBonuses: vendorBonuses
        )
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            List {
                cardPreviewSection
                basicInfoSection
                autoFillBannerSection
                rewardsSection
                vendorBonusesSection
                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirm = true
                        } label: {
                            HStack {
                                Spacer()
                                Label("Remove Card", systemImage: "trash")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(isEditing ? "Edit Card" : "Add Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEditing ? "Save" : "Add") { saveCard() }
                        .fontWeight(.semibold)
                        .disabled(!isFormValid)
                }
            }
            .confirmationDialog(
                "Remove \(existingCard?.name ?? "Card")?",
                isPresented: $showingDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Remove Card", role: .destructive) {
                    if let card = existingCard,
                       let index = store.cards.firstIndex(where: { $0.id == card.id }) {
                        store.deleteCards(at: IndexSet([index]))
                    }
                    dismiss()
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }

    // MARK: Sections

    private var cardPreviewSection: some View {
        Section {
            CardVisualView(card: previewCard)
                .frame(maxWidth: .infinity)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .padding(.vertical, 8)
        }
    }

    private var basicInfoSection: some View {
        Section("Card Details") {
            VStack(alignment: .leading, spacing: 0) {
                TextField("Card name (e.g. Chase Sapphire)", text: $name)
                    .onChange(of: name) { _, newValue in
                        guard !isEditing else { return }
                        debouncedSearch(query: newValue)
                    }

                // Typeahead suggestions
                if !suggestions.isEmpty {
                    Divider().padding(.vertical, 4)
                    ForEach(suggestions, id: \.cardName) { entry in
                        Button {
                            applyAutoFill(entry)
                        } label: {
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(entry.suggestedColor.gradient)
                                    .frame(width: 24, height: 24)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(entry.cardName)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.primary)
                                    Text(entry.notes.prefix(60) + (entry.notes.count > 60 ? "…" : ""))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Image(systemName: "sparkles")
                                    .font(.caption)
                                    .foregroundStyle(.yellow)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }

            HStack {
                Text("Last 4 digits")
                Spacer()
                TextField("Optional", text: $lastFour)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numberPad)
                    .frame(width: 80)
                    .onChange(of: lastFour) { _, new in
                        lastFour = String(new.prefix(4).filter(\.isNumber))
                    }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Card color")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                colorPicker
            }
        }
    }

    // MARK: Auto-fill banner

    @ViewBuilder
    private var autoFillBannerSection: some View {
        if showAutoFillBanner {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.yellow)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Rewards auto-filled")
                            .font(.subheadline.weight(.medium))
                        if !autoFillNotes.isEmpty {
                            Text(autoFillNotes)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Button("Clear") {
                        categoryRewards = [:]
                        vendorBonuses = []
                        baseReward = 1.0
                        showAutoFillBanner = false
                        autoFillNotes = ""
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    @ViewBuilder
    private var rewardsSection: some View {
        Section {
            HStack {
                Label("Base / default reward", systemImage: "percent")
                Spacer()
                TextField("1.0", value: $baseReward, format: .number)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.decimalPad)
                    .frame(width: 60)
                Text("%")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Rewards")
        } footer: {
            Text("The base rate applies to any category you don't specify below.")
        }

        Section {
            ForEach(RewardCategory.allCases.filter { $0 != .other }) { category in
                CategoryRewardRow(
                    category: category,
                    value: Binding(
                        get: { categoryRewards[category] },
                        set: { newValue in
                            if let value = newValue {
                                categoryRewards[category] = value
                            } else {
                                categoryRewards.removeValue(forKey: category)
                            }
                        }
                    )
                )
            }
        } header: {
            Text("Bonus categories")
        } footer: {
            Text("Leave a category blank to use the base rate.")
        }
    }

    // MARK: Vendor bonuses

    private var vendorBonusesSection: some View {
        Section {
            ForEach($vendorBonuses) { $bonus in
                VendorBonusRow(bonus: $bonus)
            }
            .onDelete { offsets in
                vendorBonuses.remove(atOffsets: offsets)
            }

            Button {
                withAnimation {
                    vendorBonuses.append(VendorBonus(vendorName: "", rewardRate: 0))
                }
            } label: {
                Label("Add Vendor Bonus", systemImage: "plus.circle")
                    .font(.subheadline)
            }
        } header: {
            Text("Vendor-specific bonuses")
        } footer: {
            Text("Earn extra rewards at specific stores (e.g. 5% at Amazon, 14x at Hilton).")
        }
    }

    // MARK: Color picker

    private var colorPicker: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4),
            spacing: 12
        ) {
            ForEach(CardColor.allCases) { color in
                Button {
                    selectedColor = color
                } label: {
                    ZStack {
                        Circle()
                            .fill(color.gradient)
                            .frame(width: 38, height: 38)
                        if selectedColor == color {
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .accessibilityLabel(color.rawValue)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: Auto-fill logic

    private func debouncedSearch(query: String) {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled else { return }
            suggestions = CardRewardsDatabase.search(query: query)
        }
    }

    private func applyAutoFill(_ entry: KnownCardRewards) {
        name = entry.cardName
        baseReward = entry.baseReward
        categoryRewards = entry.categoryRewards
        vendorBonuses = entry.vendorBonuses
        selectedColor = entry.suggestedColor
        autoFillNotes = entry.notes
        showAutoFillBanner = !entry.notes.isEmpty
        suggestions = []
    }

    // MARK: Save

    private func saveCard() {
        let rewardsDict = Dictionary(
            uniqueKeysWithValues: categoryRewards.map { ($0.key.rawValue, $0.value) }
        )
        // Filter out vendor bonuses with empty names or zero rates
        let cleanedBonuses = vendorBonuses.filter {
            !$0.vendorName.trimmingCharacters(in: .whitespaces).isEmpty && $0.rewardRate > 0
        }
        let trimmedName = name.trimmingCharacters(in: .whitespaces)

        if isEditing, var updated = existingCard {
            updated.name         = trimmedName
            updated.lastFour     = lastFour
            updated.cardColor    = selectedColor
            updated.baseReward   = baseReward
            updated.rewards      = rewardsDict
            updated.vendorBonuses = cleanedBonuses
            store.updateCard(updated)
        } else {
            let newCard = CreditCard(
                name: trimmedName,
                lastFour: lastFour,
                cardColor: selectedColor,
                rewards: rewardsDict,
                baseReward: baseReward,
                vendorBonuses: cleanedBonuses
            )
            store.addCard(newCard)
        }
        dismiss()
    }
}

// MARK: - Category Reward Row

struct CategoryRewardRow: View {
    let category: RewardCategory
    @Binding var value: Double?
    @State private var text: String = ""

    var body: some View {
        HStack {
            Label(category.rawValue, systemImage: category.icon)
            Spacer()
            TextField("Base", text: $text)
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
                .frame(width: 60)
                .onChange(of: text) { _, new in
                    let cleaned = new.trimmingCharacters(in: .whitespaces)
                    if cleaned.isEmpty {
                        value = nil
                    } else if let v = Double(cleaned) {
                        value = v
                    }
                    // Partial input (e.g. "3.") – leave binding unchanged until valid
                }
            Text("%")
                .foregroundStyle(.secondary)
        }
        .onAppear {
            if let v = value {
                text = String(v)
            }
        }
    }
}

// MARK: - Vendor Bonus Row

struct VendorBonusRow: View {
    @Binding var bonus: VendorBonus
    @State private var rateText: String = ""

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "storefront")
                .foregroundStyle(.orange)
                .frame(width: 24)
            TextField("Vendor name", text: $bonus.vendorName)
                .font(.subheadline)
            Spacer()
            TextField("0", text: $rateText)
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
                .frame(width: 60)
                .onChange(of: rateText) { _, new in
                    let cleaned = new.trimmingCharacters(in: .whitespaces)
                    if let v = Double(cleaned) {
                        bonus.rewardRate = v
                    }
                }
            Text("%")
                .foregroundStyle(.secondary)
        }
        .onAppear {
            if bonus.rewardRate > 0 {
                rateText = String(bonus.rewardRate)
            }
        }
    }
}
