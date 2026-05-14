//
//  TrainIdentifier.swift
//  RailMapiOS
//
//  Result of parsing a user-input train identifier.
//  Carries normalized form + detected service for downstream use.
//

import Foundation

struct TrainIdentifier: Equatable, Hashable, Sendable {
    /// Original user input (untouched).
    let raw: String
    /// Normalized: trimmed, uppercased, no internal whitespace.
    let normalized: String
    /// Numeric part (e.g. "6123" from "TGV6123").
    let number: String
    /// Optional alphabetical prefix (e.g. "TGV", "ICE", nil for plain digits).
    let prefix: String?
    /// Detected service. May be `.unknown` for generic numeric input.
    let service: TrainService
}
