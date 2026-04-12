//
//  JourneyDataClient.swift
//  RailMapiOS
//
//  TCA Dependency wrapping JourneyDataService.
//

import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct JourneyDataClient {
    var getDepartureStop: @Sendable (_ journey: Journey) -> Stop? = { _ in nil }
    var getArrivalStop: @Sendable (_ journey: Journey) -> Stop? = { _ in nil }
}

extension JourneyDataClient: DependencyKey {
    static let liveValue: Self = {
        let service = JourneyDataService()
        return Self(
            getDepartureStop: { journey in service.getDepartureStop(journey) },
            getArrivalStop: { journey in service.getArrivalStop(journey) }
        )
    }()
}

extension DependencyValues {
    var journeyDataClient: JourneyDataClient {
        get { self[JourneyDataClient.self] }
        set { self[JourneyDataClient.self] = newValue }
    }
}
