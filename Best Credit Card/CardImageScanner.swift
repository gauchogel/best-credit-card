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
    /// Known reward structure if the card name matched the database.
    var suggestedRewards: KnownCardRewards?

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

    /// Scans a screenshot and returns ALL detected cards.
    /// Recognises masked-number patterns like "Amazon (...1716)" used by banking apps.
    /// Falls back to single-card extraction if no multi-card patterns are found.
    static func scanMultiple(image: UIImage) async throws -> [ScannedCardInfo] {
        guard let cgImage = image.cgImage else {
            throw ScanError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = false
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
                    .map { clean($0) }
                    .filter { !$0.isEmpty }

                var results = parseMultiple(lines: lines)

                // Fall back to single-card scan if no banking-app patterns matched
                if results.isEmpty {
                    let single = parse(lines: lines)
                    if !single.isEmpty { results = [single] }
                }

                continuation.resume(returning: results)
            }
        }
    }

    // MARK: - Text Cleaning

    private static func clean(_ s: String) -> String {
        s.replacingOccurrences(of: "[®™]", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Multi-card Parsing
    //
    // Banking apps (Chase, Amex, etc.) show cards in a list with masked numbers
    // like "Amazon (...1716) >" or "Sapphire Reserve (…7835)".
    // Each such line is a separate card entry.

    private static func parseMultiple(lines: [String]) -> [ScannedCardInfo] {
        var results: [ScannedCardInfo] = []
        var seenLastFours = Set<String>()

        for (index, line) in lines.enumerated() {
            // Match patterns: (...1234)  (…1234)  (···1234)  (...1234)
            guard let lastFour = firstCapture(
                pattern: #"\(\s*[.…·]{1,4}\s*(\d{4})\s*\)"#, in: line
            ) else { continue }

            guard seenLastFours.insert(lastFour).inserted else { continue }

            // Name part = text before the "(" on the same line, stripped of trailing ">"
            let rawNamePart = (line.components(separatedBy: "(").first ?? "")
                .replacingOccurrences(of: ">", with: "")
                .trimmingCharacters(in: .whitespaces)

            // Context window: this line + up to 5 lines below (card image text, branding)
            let contextEnd = min(lines.count, index + 6)
            let contextLines = Array(lines[index..<contextEnd])

            // Try database keyword match; fall back to the raw name from the line
            let name = extractNameFromContext(contextLines, fallback: rawNamePart)
            let suggested = CardRewardsDatabase.exactMatch(for: name)

            results.append(ScannedCardInfo(
                name: name,
                lastFour: lastFour,
                suggestedRewards: suggested
            ))
        }

        return results
    }

    /// Scores context lines against the name table; returns the best match or `fallback`.
    private static func extractNameFromContext(_ lines: [String], fallback: String) -> String {
        let upperJoined = lines.map { $0.uppercased() }.joined(separator: " ")

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

        return bestScore > 0 ? bestName : fallback
    }

    // MARK: - Single-card Parsing (fallback)

    private static func parse(lines: [String]) -> ScannedCardInfo {
        let name = extractName(from: lines)
        let lastFour = extractLastFour(from: lines)
        let suggested = CardRewardsDatabase.exactMatch(for: name)
        return ScannedCardInfo(name: name, lastFour: lastFour, suggestedRewards: suggested)
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
        ("Chase Sapphire Preferred",        ["SAPPHIRE", "PREFERRED"]),
        ("Chase Freedom Unlimited",         ["FREEDOM", "UNLIMITED"]),
        ("Chase Freedom Flex",              ["FREEDOM", "FLEX"]),
        ("Chase United Explorer Card",      ["UNITED", "EXPLORER"]),
        ("Chase United Club Infinite",      ["UNITED", "CLUB", "INFINITE"]),
        ("Chase Ink Business Preferred",    ["INK", "PREFERRED", "BUSINESS"]),
        ("Chase Ink Business Unlimited",    ["INK", "UNLIMITED", "BUSINESS"]),
        ("Chase Ink Business Cash",         ["INK", "CASH", "BUSINESS"]),
        ("Chase Amazon Prime Visa",         ["AMAZON", "PRIME"]),
        // Amex
        ("Amex Platinum",                   ["PLATINUM", "PLAT"]),
        ("Amex Gold",                       ["AMEX GOLD", "AMERICAN EXPRESS GOLD"]),
        ("Amex Green",                      ["AMEX GREEN", "AMERICAN EXPRESS GREEN"]),
        ("Amex Blue Cash Preferred",        ["BLUE CASH", "PREFERRED"]),
        ("Amex Blue Cash Everyday",         ["BLUE CASH", "EVERYDAY"]),
        ("Amex Delta SkyMiles Platinum",    ["DELTA", "SKYMILES", "PLATINUM"]),
        ("Amex Delta SkyMiles Gold",        ["DELTA", "SKYMILES", "GOLD"]),
        ("Amex Hilton Honors Aspire",       ["HILTON", "ASPIRE"]),
        ("Amex Hilton Honors Surpass",      ["HILTON", "SURPASS"]),
        ("Amex Hilton Honors",              ["HILTON", "HONORS"]),
        ("Amex Marriott Bonvoy Brilliant",  ["MARRIOTT", "BRILLIANT"]),
        ("Amex Marriott Bonvoy",            ["MARRIOTT", "BONVOY"]),
        // Citi
        ("Citi Double Cash",                ["DOUBLE CASH"]),
        ("Citi Custom Cash",                ["CUSTOM CASH"]),
        ("Citi Premier",                    ["CITI PREMIER"]),
        ("Citi Strata Premier",             ["STRATA", "PREMIER"]),
        ("Citi Rewards+",                   ["REWARDS+"]),
        // Capital One
        ("Capital One Venture X",           ["VENTURE X"]),
        ("Capital One Venture",             ["VENTURE"]),
        ("Capital One Quicksilver",         ["QUICKSILVER"]),
        ("Capital One Savor",               ["SAVOR"]),
        ("Capital One SavorOne",            ["SAVORONE"]),
        // Discover
        ("Discover it Cash Back",           ["DISCOVER", "CASH BACK"]),
        ("Discover it Miles",               ["DISCOVER", "MILES"]),
        ("Discover it Chrome",              ["DISCOVER", "CHROME"]),
        // Wells Fargo
        ("Wells Fargo Active Cash",         ["ACTIVE CASH", "WELLS FARGO"]),
        ("Wells Fargo Autograph",           ["AUTOGRAPH", "WELLS FARGO"]),
        // Bank of America
        ("Bank of America Customized Cash", ["CUSTOMIZED CASH", "BANK OF AMERICA"]),
        ("Bank of America Premium Rewards", ["PREMIUM REWARDS", "BANK OF AMERICA"]),
        // US Bank
        ("US Bank Cash+",                  ["CASH+", "U.S. BANK", "US BANK"]),
        ("US Bank Altitude Connect",       ["ALTITUDE CONNECT"]),
        ("US Bank Altitude Reserve",       ["ALTITUDE RESERVE"]),
        // Apple / Other
        ("Apple Card",                      ["APPLE CARD"]),
        ("Bilt Mastercard",                 ["BILT"]),
        ("PayPal Cashback Mastercard",      ["PAYPAL"]),
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
                digitCount < line.count / 2,
                !line.hasPrefix("$"),
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
