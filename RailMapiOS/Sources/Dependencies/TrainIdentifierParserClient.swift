//
//  TrainIdentifierParserClient.swift
//  RailMapiOS
//
//  Thin TCA adapter for the parser layer.
//  Reducers consume this; tests can inject mock parsers via testValue.
//

import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct TrainIdentifierParserClient {
    /// Parses raw user input into a `TrainIdentifier`. Returns nil if the
    /// input does not match any known pattern.
    var parse: @Sendable (_ input: String) -> TrainIdentifier? = { _ in nil }
}

extension TrainIdentifierParserClient: DependencyKey {
    static let liveValue = Self(
        parse: { input in CompositeTrainParser.default.parse(input) }
    )

    /// Convenience for previews and tests: always succeeds with a TGV.
    static let previewValue = Self(
        parse: { input in
            TrainIdentifier(
                raw: input,
                normalized: input.uppercased(),
                number: "6123",
                prefix: "TGV",
                service: .sncfTGV
            )
        }
    )
}

extension DependencyValues {
    var trainIdentifierParser: TrainIdentifierParserClient {
        get { self[TrainIdentifierParserClient.self] }
        set { self[TrainIdentifierParserClient.self] = newValue }
    }
}
