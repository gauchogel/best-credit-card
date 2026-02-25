//
//  CardImageScanner.swift
//  Best Credit Card
//

import Foundation
import Vision
import UIKit

// MARK: - Scanned Card Info

struct ScannedCardInfo {
    /// Best-guess card name extracted from OCR. Empty string if not detected.
    var name: String
    /// Last 4 digits of the card number. Empty string if not detected.
    var lastFour: String

    var isEmpty: Bool { name.isEmpty && lastFour.isEmpty }
}

// MARK: - Errors

enum ScanError: LocalizedError {
    case invalidImage
    case visionFailed(Error)

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Could not load the selected image."
        case .visionFailed(let underlying):
            return "Text recognition failed: \(underlying.localizedDescription)"
        }
    }
}

// MARK: - Scanner

struct CardImageScanner {

    // MARK: Public API

    /// Runs Vision OCR on `image` off the main thread and returns detected card info.
    /// Never throws for "nothing found" — only for system-level Vision failures.
    static func scan(image: UIImage) async throws -> ScannedCardInfo {
        guard let cgImage = image.cgImage else {
            throw ScanError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = false   // keeps numbers/names intact
                request.recognitionLanguages = ["en-US"]

                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: ScanError.visionFailed(error))
                    return
                }

                let lines = (request.results ?? [])
                    .compactMap { $0.topCandidates(1).first?.string }
                    .map { clean($0) }          // strip ® ™ and trim
                    .filter { !$0.isEmpty }

                continuation.resume(returning: parse(lines: lines))
            }
        }
    }

    // MARK: - Text Cleaning

    private static func clean(_ s: String) -> String {
        s.replacingOccurrences(of: "[®™]", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Parsing

    private static func parse(lines: [String]) -> ScannedCardInfo {
        ScannedCardInfo(
            name: extractName(from: lines),
            lastFour: extractLastFour(from: lines)
        )
    }

    // MARK: Last-four extraction

    private static func extractLastFour(from lines: [String]) -> String {
        let joined = lines.joined(separator: "\n")

        // Priority 1: masked digits — "•••• 1234" / "**** 1234" / ".... 1234"
        if let m = firstCapture(pattern: #"[•·.\*]{3,4}\s*(\d{4})"#, in: joined) { return m }

        // Priority 2: "ending in 1234" / "ends in 1234"
        if let m = firstCapture(pattern: #"endin?g?\s+in\s+(\d{4})"#, in: joined,
                                options: .caseInsensitive) { return m }

        // Priority 3: space-separated 16-digit PAN — capture last group
        if let m = firstCapture(
            pattern: #"\b\d{4}\s+\d{4}\s+\d{4}\s+(\d{4})\b"#, in: joined) { return m }

        // Priority 4: bare 16-digit string — take last 4 chars
        if let m = firstCapture(pattern: #"\b(\d{16})\b"#, in: joined) {
            return String(m.suffix(4))
        }

        // Priority 5: standalone 4-digit line
        for line in lines where line.count == 4 && line.allSatisfy(\.isNumber) {
            return line
        }

        return ""
    }

    // MARK: Card name extraction

    /// Keyword scoring table: canonical name → uppercase keywords.
    private static let nameTable: [(name: String, keywords: [String])] = [
        // Chase
        ("Chase Sapphire Reserve",          ["SAPPHIRE", "RESERVE"]),
        ("Chase Sapphire Preferred",         ["SAPPHIRE", "PREFERRED"]),
        ("Chase Freedom Unlimited",          ["FREEDOM", "UNLIMITED"]),
        ("Chase Freedom Flex",               ["FREEDOM", "FLEX"]),
        ("Chase Ink Business Preferred",     ["INK", "PREFERRED", "BUSINESS"]),
        ("Chase Ink Business Unlimited",     ["INK", "UNLIMITED", "BUSINESS"]),
        ("Chase Ink Business Cash",          ["INK", "CASH", "BUSINESS"]),
        ("Chase Amazon Prime Visa",          ["AMAZON", "PRIME"]),
        // Amex
        ("Amex Platinum",                    ["PLATINUM", "PLAT"]),
        ("Amex Gold",                        ["AMEX GOLD", "AMERICAN EXPRESS GOLD"]),
        ("Amex Green",                       ["AMEX GREEN", "AMERICAN EXPRESS GREEN"]),
        ("Amex Blue Cash Preferred",         ["BLUE CASH", "PREFERRED"]),
        ("Amex Blue Cash Everyday",          ["BLUE CASH", "EVERYDAY"]),
        ("Amex Delta SkyMiles Platinum",     ["DELTA", "SKYMILES", "PLATINUM"]),
        ("Amex Delta SkyMiles Gold",         ["DELTA", "SKYMILES", "GOLD"]),
        ("Amex Hilton Honors Aspire",        ["HILTON", "ASPIRE"]),
        ("Amex Hilton Honors Surpass",       ["HILTON", "SURPASS"]),
        ("Amex Hilton Honors",               ["HILTON", "HONORS"]),
        ("Amex Marriott Bonvoy Brilliant",   ["MARRIOTT", "BRILLIANT"]),
        ("Amex Marriott Bonvoy",             ["MARRIOTT", "BONVOY"]),
        // Citi
        ("Citi Double Cash",                 ["DOUBLE CASH"]),
        ("Citi Custom Cash",                 ["CUSTOM CASH"]),
        ("Citi Premier",                     ["CITI PREMIER"]),
        ("Citi Strata Premier",              ["STRATA", "PREMIER"]),
        ("Citi Rewards+",                    ["REWARDS+"]),
        // Capital One
        ("Capital One Venture X",            ["VENTURE X"]),
        ("Capital One Venture",              ["VENTURE"]),
        ("Capital One Quicksilver",          ["QUICKSILVER"]),
        ("Capital One Savor",                ["SAVOR"]),
        ("Capital One SavorOne",             ["SAVORONE"]),
        // Discover
        ("Discover it Cash Back",            ["DISCOVER", "CASH BACK"]),
        ("Discover it Miles",                ["DISCOVER", "MILES"]),
        ("Discover it Chrome",               ["DISCOVER", "CHROME"]),
        // Wells Fargo
        ("Wells Fargo Active Cash",          ["ACTIVE CASH", "WELLS FARGO"]),
        ("Wells Fargo Autograph",            ["AUTOGRAPH", "WELLS FARGO"]),
        // Bank of America
        ("Bank of America Customized Cash",  ["CUSTOMIZED CASH", "BANK OF AMERICA"]),
        ("Bank of America Premium Rewards",  ["PREMIUM REWARDS", "BANK OF AMERICA"]),
        // US Bank
        ("US Bank Cash+",                   ["CASH+", "U.S. BANK", "US BANK"]),
        ("US Bank Altitude Connect",        ["ALTITUDE CONNECT"]),
        ("US Bank Altitude Reserve",        ["ALTITUDE RESERVE"]),
        // Apple / Other
        ("Apple Card",                       ["APPLE CARD"]),
        ("Bilt Mastercard",                  ["BILT"]),
        ("PayPal Cashback Mastercard",       ["PAYPAL"]),
    ]

    private static func extractName(from lines: [String]) -> String {
        let upperLines = lines.map { $0.uppercased() }
        let upperJoined = upperLines.joined(separator: " ")

        var bestName = ""
        var bestScore = 0

        for entry in nameTable {
            var score = 0
            for keyword in entry.keywords {
                if upperJoined.contains(keyword) { score += 1 }
            }
            if score > bestScore {
                bestScore = score
                bestName = entry.name
            }
        }

        if bestScore > 0 { return bestName }

        // Fallback: first OCR line that looks like a card name
        for line in lines {
            let upper = line.uppercased()
            let digitCount = line.filter(\.isNumber).count
            let letterCount = line.filter(\.isLetter).count
            guard
                line.count >= 5, line.count <= 60,
                letterCount >= 3,
                digitCount < line.count / 2,         // not mostly numbers
                !line.hasPrefix("$"),                // not a dollar amount
                !upper.contains("TRANSACTION"),
                !upper.contains("STATEMENT"),
                !upper.contains("BALANCE"),
                !upper.contains("AVAILABLE")
            else { continue }
            return line
        }

        return ""
    }

    // MARK: - Regex helper

    private static func firstCapture(
        pattern: String,
        in string: String,
        options: NSRegularExpression.Options = []
    ) -> String? {
        guard
            let regex = try? NSRegularExpression(pattern: pattern, options: options),
            let match = regex.firstMatch(
                in: string,
                range: NSRange(string.startIndex..., in: string)
            ),
            match.numberOfRanges > 1,
            let range = Range(match.range(at: 1), in: string)
        else { return nil }
        return String(string[range])
    }
}
