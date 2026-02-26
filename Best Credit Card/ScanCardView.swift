//
//  ScanCardView.swift
//  Best Credit Card
//

import SwiftUI
import PhotosUI

// MARK: - Scan Card View

struct ScanCardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CardStore.self) private var store

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var phase: ScanPhase = .picking

    private enum ScanPhase {
        case picking
        case processing
        case done([ScannedCardInfo])
        case failed(Error)
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            Group {
                switch phase {
                case .picking:
                    pickingView
                case .processing:
                    processingView
                case .done(let cards):
                    doneView(cards)
                case .failed(let error):
                    failedView(error)
                }
            }
            .navigationTitle("Import from Screenshot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Picking phase

    private var pickingView: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 72))
                .foregroundStyle(.blue)

            VStack(spacing: 10) {
                Text("Select a Screenshot")
                    .font(.title2.weight(.semibold))

                Text("Take a screenshot inside your banking app that shows your cards, then select it here. The app reads everything on-device — nothing is sent anywhere.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            PhotosPicker(
                selection: $selectedPhoto,
                matching: .screenshots,
                photoLibrary: .shared()
            ) {
                Label("Choose Screenshot", systemImage: "photo.badge.plus.fill")
                    .font(.headline)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .onChange(of: selectedPhoto) { _, item in
                guard let item else { return }
                Task { await processPhoto(item) }
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Processing phase

    private var processingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.6)
                .tint(.blue)
            Text("Reading card details…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Done phase

    private func doneView(_ cards: [ScannedCardInfo]) -> some View {
        VStack(spacing: 0) {
            Form {
                if cards.isEmpty {
                    Section {
                        Text("No cards were detected in this screenshot.")
                            .foregroundStyle(.secondary)
                    } header: {
                        Text("Detected Cards")
                    } footer: {
                        Text("Try a screenshot that shows your card names and masked numbers, like the main accounts list in your banking app.")
                    }
                } else {
                    Section {
                        ForEach(Array(cards.enumerated()), id: \.offset) { _, info in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "creditcard")
                                        .foregroundStyle(.blue)
                                        .frame(width: 22)
                                    Text(info.name.isEmpty ? "Unknown Card" : info.name)
                                        .font(.subheadline.weight(.medium))
                                    Spacer()
                                    if !info.lastFour.isEmpty {
                                        Text("···· \(info.lastFour)")
                                            .font(.caption.monospacedDigit())
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                if info.suggestedRewards != nil {
                                    HStack(spacing: 4) {
                                        Image(systemName: "sparkles")
                                            .font(.caption2)
                                            .foregroundStyle(.yellow)
                                        Text("Rewards will auto-fill")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.leading, 30)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    } header: {
                        Text("\(cards.count) Card\(cards.count == 1 ? "" : "s") Detected")
                    } footer: {
                        Text("Reward rates will be auto-filled for recognized cards. You can edit them anytime from My Cards.")
                    }
                }
            }

            VStack(spacing: 12) {
                if !cards.isEmpty {
                    Button {
                        addAllCards(cards)
                    } label: {
                        Text(cards.count == 1 ? "Add Card" : "Add All \(cards.count) Cards")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }

                Button {
                    selectedPhoto = nil
                    phase = .picking
                } label: {
                    Text("Try a Different Screenshot")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
    }

    // MARK: - Failed phase

    private func failedView(_ error: Error) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 52))
                .foregroundStyle(.orange)

            Text("Couldn't Read Screenshot")
                .font(.title3.weight(.semibold))

            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                selectedPhoto = nil
                phase = .picking
            } label: {
                Text("Try Again")
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
        .padding()
    }

    // MARK: - Add cards directly to store

    private func addAllCards(_ cards: [ScannedCardInfo]) {
        for info in cards {
            let rewards: [String: Double]
            let baseReward: Double
            let color: CardColor
            let vendorBonuses: [VendorBonus]

            if let known = info.suggestedRewards {
                rewards = Dictionary(
                    uniqueKeysWithValues: known.categoryRewards.map { ($0.key.rawValue, $0.value) }
                )
                baseReward = known.baseReward
                color = known.suggestedColor
                vendorBonuses = known.vendorBonuses
            } else {
                rewards = [:]
                baseReward = 1.0
                color = .ocean
                vendorBonuses = []
            }

            store.addCard(CreditCard(
                name: info.name.isEmpty ? "Unknown Card" : info.name,
                lastFour: info.lastFour,
                cardColor: color,
                rewards: rewards,
                baseReward: baseReward,
                vendorBonuses: vendorBonuses
            ))
        }
        dismiss()
    }

    // MARK: - Processing

    private func processPhoto(_ item: PhotosPickerItem) async {
        phase = .processing
        do {
            guard
                let data = try await item.loadTransferable(type: Data.self),
                let uiImage = UIImage(data: data)
            else {
                phase = .done([])
                return
            }
            let cards = try await CardImageScanner.scanMultiple(image: uiImage)
            phase = .done(cards)
        } catch {
            phase = .failed(error)
        }
    }
}

// MARK: - Detected Field Row (kept for potential reuse)

struct DetectedFieldRow: View {
    let label: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack {
            Label(label, systemImage: systemImage)
            Spacer()
            if value.isEmpty {
                Text("Not detected")
                    .foregroundStyle(.secondary)
                    .italic()
            } else {
                Text(value)
                    .fontWeight(.medium)
            }
        }
    }
}
