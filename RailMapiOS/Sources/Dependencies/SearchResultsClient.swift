//
//  SearchResultsClient.swift
//  RailMapiOS
//
//  Thin TCA adapter for SearchResultsService.
//

import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct SearchResultsClient {
    var groupResults: @Sendable (_ journeys: [VehicleJourney]) -> [SearchResult] = { _ in [] }
}

extension SearchResultsClient: DependencyKey {
    static let liveValue: Self = {
        let service = SearchResultsService()
        return Self(
            groupResults: { service.groupResults($0) }
        )
    }()
}

extension DependencyValues {
    var searchResultsClient: SearchResultsClient {
        get { self[SearchResultsClient.self] }
        set { self[SearchResultsClient.self] = newValue }
    }
}
