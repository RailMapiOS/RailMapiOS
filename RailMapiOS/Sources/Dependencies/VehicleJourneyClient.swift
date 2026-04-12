//
//  VehicleJourneyClient.swift
//  RailMapiOS
//
//  TCA Dependency wrapping VehicleJourneyService.
//

import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct VehicleJourneyClient {
    var fetchVehicleJourneys: @Sendable (_ headsign: String, _ source: String) async throws -> [VehicleJourney] = { _, _ in [] }
    var getPassageDays: @Sendable (_ journeys: [VehicleJourney]) -> [String: [Date]] = { _ in [:] }
}

extension VehicleJourneyClient: DependencyKey {
    static let liveValue: Self = {
        let service = VehicleJourneyService()
        return Self(
            fetchVehicleJourneys: { headsign, source in
                try await service.fetchVehicleJourneys(headsign: headsign, source: source)
            },
            getPassageDays: { journeys in
                service.getPassageDays(from: journeys)
            }
        )
    }()
}

extension DependencyValues {
    var vehicleJourneyClient: VehicleJourneyClient {
        get { self[VehicleJourneyClient.self] }
        set { self[VehicleJourneyClient.self] = newValue }
    }
}
