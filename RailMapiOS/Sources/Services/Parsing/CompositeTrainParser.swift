//
//  CompositeTrainParser.swift
//  RailMapiOS
//
//  Orchestrates provider parsers in priority order.
//  Owns input normalization (trim + uppercase + strip whitespace).
//

import Foundation

struct CompositeTrainParser: TrainParser {

    let parsers: [any TrainParser]

    init(parsers: [any TrainParser]) {
        self.parsers = parsers
    }

    /// Default chain: most-specific first (operator-prefixed), generic last.
    /// SNCF/DB/UK try first because their patterns require an alpha prefix
    /// (or the specific UK 1A23 shape), so they don't false-match digit-only input.
    static let `default` = CompositeTrainParser(parsers: [
        SNCFTrainParser(),
        DBTrainParser(),
        UKTrainParser(),
        GenericTrainParser(fallbackService: .unknown),
    ])

    func parse(_ input: String) -> TrainIdentifier? {
        let normalized = Self.normalize(input)
        guard !normalized.isEmpty else { return nil }

        for parser in parsers {
            if var result = parser.parse(normalized) {
                // Preserve the original raw input — parsers receive the normalized form.
                result = TrainIdentifier(
                    raw: input,
                    normalized: result.normalized,
                    number: result.number,
                    prefix: result.prefix,
                    service: result.service
                )
                return result
            }
        }
        return nil
    }

    // MARK: - Normalization

    /// Trim, uppercase, and strip all internal whitespace.
    /// Examples:
    ///   "  tgv 6123 "  → "TGV6123"
    ///   "ice  74"      → "ICE74"
    ///   "1a23"         → "1A23"
    static func normalize(_ input: String) -> String {
        input
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespacesAndNewlines)
            .joined()
            .uppercased()
    }
}
