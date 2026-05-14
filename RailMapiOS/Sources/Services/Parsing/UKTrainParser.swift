//
//  UKTrainParser.swift
//  RailMapiOS
//
//  Parses UK rail "headcodes": 4 chars, digit + letter + 2 digits (e.g. "1A23").
//  Reference: https://en.wikipedia.org/wiki/Train_reporting_number
//

import Foundation

struct UKTrainParser: TrainParser {

    private static let pattern = #"^(\d[A-Z]\d{2})$"#

    func parse(_ normalized: String) -> TrainIdentifier? {
        guard let groups = captures(of: normalized, pattern: Self.pattern), groups.count == 1 else {
            return nil
        }
        let headcode = groups[0]
        return TrainIdentifier(
            raw: normalized,
            normalized: normalized,
            number: headcode,
            prefix: nil,
            service: .ukHeadcode
        )
    }
}
