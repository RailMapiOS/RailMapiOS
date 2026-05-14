//
//  SNCFTrainParser.swift
//  RailMapiOS
//
//  Parses SNCF + French operator train identifiers.
//  Patterns: TGV, TER, IC/Intercités, Ouigo, Eurostar.
//

import Foundation

struct SNCFTrainParser: TrainParser {

    /// Pattern table — order matters (most specific first).
    /// Capture groups: (prefix, number).
    private static let patterns: [(regex: String, service: TrainService)] = [
        (#"^(TGV)(\d{3,5})$"#,                           .sncfTGV),
        (#"^(OUIGO)(\d{3,5})$"#,                         .ouigo),
        (#"^(EUROSTAR|EST|EUR)(\d{4})$"#,                .eurostar),
        (#"^(TER)(\d{1,6})$"#,                           .sncfTER),
        (#"^(INTERCITES?|IC)(\d{2,5})$"#,                .sncfIntercites),
    ]

    func parse(_ normalized: String) -> TrainIdentifier? {
        for (pattern, service) in Self.patterns {
            guard let groups = captures(of: normalized, pattern: pattern), groups.count == 2 else { continue }
            return TrainIdentifier(
                raw: normalized,
                normalized: normalized,
                number: groups[1],
                prefix: groups[0],
                service: service
            )
        }
        return nil
    }
}
