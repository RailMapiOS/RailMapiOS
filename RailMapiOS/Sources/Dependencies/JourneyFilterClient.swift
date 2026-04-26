//
//  JourneyFilterClient.swift
//  RailMapiOS
//
//  Thin TCA adapter for JourneyFilterService.
//

import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct JourneyFilterClient {
    var filterJourneys: @Sendable (_ allJourneys: [Journey], _ searchText: String) -> [Journey] = { journeys, _ in journeys }
    var buildDateRows: @Sendable (
        _ vehicleJourneys: [VehicleJourney],
        _ departureStationID: String?,
        _ arrivalStationID: String?
    ) -> [DateRow] = { _, _, _ in [] }
    var resolveCompany: @Sendable (_ journey: VehicleJourney) -> String? = { _ in nil }
}

extension JourneyFilterClient: DependencyKey {
    static let liveValue: Self = {
        let service = JourneyFilterService()
        return Self(
            filterJourneys: { service.filter(journeys: $0, by: $1) },
            buildDateRows: { service.buildDateRows(from: $0, departureStationID: $1, arrivalStationID: $2) },
            resolveCompany: { service.resolveCompany(from: $0) }
        )
    }()
}

extension DependencyValues {
    var journeyFilterClient: JourneyFilterClient {
        get { self[JourneyFilterClient.self] }
        set { self[JourneyFilterClient.self] = newValue }
    }
}
