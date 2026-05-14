//
//  VehicleJourneyClient.swift
//  RailMapiOS
//
//  Thin TCA adapter for VehicleJourneyService.
//

import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct VehicleJourneyClient {
    var fetchVehicleJourneys: @Sendable (_ headsign: String, _ source: String) async throws -> [VehicleJourney] = { _, _ in [] }
    var fetchTrainInfo: @Sendable (_ trainNumber: String, _ source: String?) async throws -> TrainInfoResult
    var getPassageDays: @Sendable (_ journeys: [VehicleJourney]) -> [String: [Date]] = { _ in [:] }
}

extension VehicleJourneyClient: DependencyKey {
    static let liveValue: Self = {
        let service = VehicleJourneyService()
        return Self(
            fetchVehicleJourneys: { try await service.fetchVehicleJourneys(headsign: $0, source: $1) },
            fetchTrainInfo: { try await service.fetchTrainInfo(trainNumber: $0, source: $1) },
            getPassageDays: { service.passageDays(from: $0) }
        )
    }()
}

extension DependencyValues {
    var vehicleJourneyClient: VehicleJourneyClient {
        get { self[VehicleJourneyClient.self] }
        set { self[VehicleJourneyClient.self] = newValue }
    }
}
