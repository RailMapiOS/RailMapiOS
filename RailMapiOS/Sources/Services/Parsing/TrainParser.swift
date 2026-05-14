//
//  TrainParser.swift
//  RailMapiOS
//
//  Provider-oriented parser protocol.
//  Each implementation knows the patterns of one operator family.
//

import Foundation

protocol TrainParser: Sendable {
    /// Returns a `TrainIdentifier` if the (already normalized) input matches
    /// any pattern this parser knows. Returns nil otherwise.
    /// - Parameter normalized: input already trimmed, uppercased, no whitespace.
    func parse(_ normalized: String) -> TrainIdentifier?
}

// MARK: - Regex helper (shared)

extension TrainParser {
    /// Tries to match `normalized` against `pattern`. On success, returns the
    /// captured groups as substrings, in order.
    func captures(of normalized: String, pattern: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(normalized.startIndex..<normalized.endIndex, in: normalized)
        guard let match = regex.firstMatch(in: normalized, range: range),
              match.range == range else { return nil }

        var groups: [String] = []
        for i in 1..<match.numberOfRanges {
            let r = match.range(at: i)
            if r.location == NSNotFound {
                groups.append("")
            } else if let swiftRange = Range(r, in: normalized) {
                groups.append(String(normalized[swiftRange]))
            }
        }
        return groups
    }
}
