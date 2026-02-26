//
//  NearbyView.swift
//  Best Credit Card
//

import SwiftUI
import CoreLocation

// MARK: - Nearby View

struct NearbyView: View {
    @Environment(CardStore.self) private var store
    @Environment(LocationManager.self) private var locationManager

    @State private var merchants: [NearbyMerchant] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var hasLoadedOnce = false

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
            // Will retry via onChange when location arrives
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            merchants = try await NearbyService.fetch(near: location)
            hasLoadedOnce = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - Nearby Merchant Row

struct NearbyMerchantRow: View {
    @Environment(CardStore.self) private var store
    let merchant: NearbyMerchant

    private var bestCard: (card: CreditCard, rate: Double)? {
        store.rankedCards(for: merchant.category).first
    }

    var body: some View {
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

                    Text(String(format: "%.1f%%", best.rate))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}
