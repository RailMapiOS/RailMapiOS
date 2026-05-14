//
//  GenericTrainParser.swift
//  RailMapiOS
//
//  Last-resort parser: digits-only train numbers without operator prefix.
//  Most users type just the number (e.g. "6234"), so this is the most common case.
//

import Foundation

struct GenericTrainParser: TrainParser {

    /// 4 to 6 digits — enforces a minimum length so partial input
    /// (single keystrokes like "6", "68") is rejected and no premature API call fires.
    /// Real European train numbers are virtually always ≥ 4 digits.
    private static let pattern = #"^(\d{4,6})$"#

    /// Service to assume when the operator is unknown.
    /// Defaults to `.unknown`; callers can override (e.g. set to `.sncfTER` if app is France-first).
    let fallbackService: TrainService

    init(fallbackService: TrainService = .unknown) {
        self.fallbackService = fallbackService
    }

    func parse(_ normalized: String) -> TrainIdentifier? {
        guard let groups = captures(of: normalized, pattern: Self.pattern), groups.count == 1 else {
            return nil
        }
        return TrainIdentifier(
            raw: normalized,
            normalized: normalized,
            number: groups[0],
            prefix: nil,
            service: fallbackService
        )
    }
}
