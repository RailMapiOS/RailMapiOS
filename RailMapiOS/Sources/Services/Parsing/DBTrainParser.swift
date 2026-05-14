//
//  DBTrainParser.swift
//  RailMapiOS
//
//  Parses Deutsche Bahn train identifiers.
//  Patterns: ICE, IC/EC, RE, RB.
//

import Foundation

struct DBTrainParser: TrainParser {

    /// Order matters — ICE before IC (otherwise "ICE74" matches "IC" prefix).
    private static let patterns: [(regex: String, service: TrainService)] = [
        (#"^(ICE)(\d{1,4})$"#,        .dbICE),
        (#"^(IC|EC)(\d{1,4})$"#,      .dbIC),
        (#"^(RE)(\d{1,5})$"#,         .dbRE),
        (#"^(RB)(\d{1,5})$"#,         .dbRB),
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
