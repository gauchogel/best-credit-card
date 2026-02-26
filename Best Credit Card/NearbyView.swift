//
//  NearbyView.swift
//  Best Credit Card
//

import SwiftUI
import CoreLocation
import MapKit

// MARK: - Nearby View

struct NearbyView: View {
    @Environment(CardStore.self) private var store
    @Environment(LocationManager.self) private var locationManager

    @State private var merchants: [NearbyMerchant] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var hasLoadedOnce = false
    @State private var locationLabel = ""

    var body: some View {
        NavigationStack {
            Group {
                switch locationManager.authorizationStatus {
                case .notDetermined:
                    permissionPrompt
                case .denied, .restricted:
                    deniedView
                case .authorizedWhenInUse, .authorizedAlways:
                    if store.cards.isEmpty {
                        noCardsView
                    } else {
                        merchantList
                    }
                @unknown default:
                    permissionPrompt
                }
            }
            .navigationTitle("Nearby")
        }
    }

    // MARK: - Permission Prompt

    private var permissionPrompt: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            Text("Find Nearby Merchants")
                .font(.title2.weight(.semibold))

            Text("Allow location access to see merchants near you and which card earns the best rewards.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                locationManager.requestPermission()
            } label: {
                Label("Enable Location", systemImage: "location.fill")
                    .font(.headline)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Denied View

    private var deniedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.slash.fill")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("Location Access Denied")
                .font(.title2.weight(.semibold))

            Text("Open Settings and enable location access for Best Credit Card to see nearby merchants.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - No Cards View

    private var noCardsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("Add Cards First")
                .font(.title2.weight(.semibold))
            Text("Add your credit cards in the My Cards tab to see which card to use at nearby merchants.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: - Merchant List

    private var merchantList: some View {
        Group {
            if isLoading && merchants.isEmpty {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.4)
                    Text("Finding nearby merchants…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else if let error = errorMessage, merchants.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange)
                    Text("Couldn't load merchants")
                        .font(.headline)
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Button("Try Again") {
                        Task { await loadMerchants() }
                    }
                    .buttonStyle(.bordered)
                }
            } else if merchants.isEmpty && hasLoadedOnce {
                VStack(spacing: 16) {
                    Image(systemName: "mappin.slash")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No merchants found nearby")
                        .font(.headline)
                    Text("Try moving to a different area or pull down to refresh.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if !locationLabel.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "mappin")
                                    .font(.caption2)
                                    .foregroundStyle(.red)
                                Text(locationLabel)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal, 4)
                        }

                        ForEach(merchants) { merchant in
                            NearbyMerchantRow(merchant: merchant)
                        }
                    }
                    .padding()
                }
                .refreshable {
                    await loadMerchants()
                }
            }
        }
        .task {
            guard !hasLoadedOnce else { return }
            await loadMerchants()
        }
        .onChange(of: locationManager.location) { _, newLocation in
            guard !hasLoadedOnce, newLocation != nil else { return }
            Task { await loadMerchants() }
        }
    }

    // MARK: - Load

    private func loadMerchants() async {
        guard let location = locationManager.location else {
            locationManager.startUpdating()
            return
        }

        isLoading = true
        errorMessage = nil
        reverseGeocode(location)

        do {
            merchants = try await NearbyService.fetch(near: location)
            hasLoadedOnce = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func reverseGeocode(_ location: CLLocation) {
        Task {
            guard let placemarks = try? await CLGeocoder().reverseGeocodeLocation(location),
                  let p = placemarks.first else { return }
            let parts = [p.locality, p.administrativeArea].compactMap { $0 }
            locationLabel = parts.joined(separator: ", ")
        }
    }
}

// MARK: - Nearby Merchant Row

struct NearbyMerchantRow: View {
    @Environment(CardStore.self) private var store
    let merchant: NearbyMerchant
    @State private var showingDetail = false

    private var bestCard: RankedCard? {
        store.rankedCards(for: merchant.category, merchantName: merchant.name).first
    }

    var body: some View {
        Button {
            showingDetail = true
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                // Merchant info
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.12))
                            .frame(width: 42, height: 42)
                        Image(systemName: merchant.category.icon)
                            .font(.body)
                            .foregroundStyle(.blue)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(merchant.name)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        if !merchant.address.isEmpty {
                            Text(merchant.address)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(merchant.distanceText)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                        Text(merchant.category.rawValue)
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                // Best card recommendation
                if let best = bestCard {
                    Divider()
                    HStack(spacing: 10) {
                        CardVisualView(card: best.card, compact: true)
                            .frame(width: 60)

                        VStack(alignment: .leading, spacing: 1) {
                            Text("Use \(best.card.name)")
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                            if !best.card.lastFour.isEmpty {
                                Text("···· \(best.card.lastFour)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(String(format: "%.1f%%", best.rate))
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.green)
                            if case .vendorBonus(let name) = best.source {
                                Label(name, systemImage: "storefront")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDetail) {
            NearbyMerchantDetailView(merchant: merchant)
        }
    }
}

// MARK: - Merchant Detail View

struct NearbyMerchantDetailView: View {
    @Environment(CardStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let merchant: NearbyMerchant

    private var rankedCards: [RankedCard] {
        store.rankedCards(for: merchant.category, merchantName: merchant.name)
    }

    var body: some View {
        NavigationStack {
            List {
                // Place info
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(merchant.name)
                            .font(.title2.bold())
                        if !merchant.address.isEmpty {
                            Text(merchant.address)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Label(merchant.distanceText, systemImage: "location")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 4)
                }

                // Best card
                if let best = rankedCards.first {
                    Section("Best Card") {
                        DetailCardRow(card: best.card, rate: best.rate, isBest: true, source: best.source)
                    }
                } else {
                    Section("Best Card") {
                        Text("Add cards in My Cards tab to see recommendations.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                // Other cards
                if rankedCards.count > 1 {
                    Section("Your Other Cards") {
                        ForEach(Array(rankedCards.dropFirst())) { item in
                            DetailCardRow(card: item.card, rate: item.rate, isBest: false, source: item.source)
                        }
                    }
                }

                // Category info
                Section("Category") {
                    Label(merchant.category.rawValue, systemImage: merchant.category.icon)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if !merchant.googleTypes.isEmpty {
                        Text(merchant.googleTypes.prefix(4).joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Card Recommendation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Detail Card Row

struct DetailCardRow: View {
    let card: CreditCard
    let rate: Double
    let isBest: Bool
    var source: RewardSource = .categoryBonus

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            CardVisualView(card: card, compact: true)
                .frame(width: 64)
                .overlay(alignment: .topTrailing) {
                    if isBest {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                            .offset(x: 4, y: -4)
                    }
                }

            VStack(alignment: .leading, spacing: 3) {
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

            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f%%", rate))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(isBest ? .green : .secondary)
                if case .vendorBonus(let name) = source {
                    Label(name, systemImage: "storefront")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
