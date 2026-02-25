//
//  ScanCardView.swift
//  Best Credit Card
//

import SwiftUI
import PhotosUI

// MARK: - Scan Card View

struct ScanCardView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var phase: ScanPhase = .picking
    @State private var scannedInfo: ScannedCardInfo?
    @State private var showingAddCard = false

    private enum ScanPhase {
        case picking
        case processing
        case done(ScannedCardInfo)
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
                case .done(let info):
                    doneView(info)
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
        .sheet(isPresented: $showingAddCard) {
            if let info = scannedInfo {
                AddEditCardView(scannedInfo: info)
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

                Text("Take a screenshot inside your banking app that shows your card name and number, then select it here. The app reads everything on-device — nothing is sent anywhere.")
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

    private func doneView(_ info: ScannedCardInfo) -> some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    DetectedFieldRow(
                        label: "Card Name",
                        value: info.name,
                        systemImage: "creditcard"
                    )
                    DetectedFieldRow(
                        label: "Last 4 Digits",
                        value: info.lastFour,
                        systemImage: "number"
                    )
                } header: {
                    Text("Detected Info")
                } footer: {
                    if info.isEmpty {
                        Text("Nothing was detected. You can still continue and fill everything in manually.")
                    } else {
                        Text("Review the info above. You can edit anything — and fill in your reward rates — on the next screen.")
                    }
                }
            }

            VStack(spacing: 12) {
                Button {
                    scannedInfo = info
                    showingAddCard = true
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
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

    // MARK: - Processing

    private func processPhoto(_ item: PhotosPickerItem) async {
        phase = .processing
        do {
            guard
                let data = try await item.loadTransferable(type: Data.self),
                let uiImage = UIImage(data: data)
            else {
                phase = .done(ScannedCardInfo(name: "", lastFour: ""))
                return
            }
            let info = try await CardImageScanner.scan(image: uiImage)
            phase = .done(info)
        } catch {
            phase = .failed(error)
        }
    }
}

// MARK: - Detected Field Row

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
