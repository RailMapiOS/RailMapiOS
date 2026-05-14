//
//  RealtimeClient.swift
//  RailMapiOS
//
//  Thin TCA adapter for RealtimeService.
//

import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct RealtimeClient {
    var fetchTripUpdate: @Sendable (_ tripID: String, _ source: String) async throws -> TripUpdateDTO?
    var fetchVehiclePosition: @Sendable (_ tripID: String, _ source: String) async throws -> VehiclePositionDTO?
    var fetchAlerts: @Sendable (_ source: String, _ tripID: String?) async throws -> [AlertDTO] = { _, _ in [] }
}

extension RealtimeClient: DependencyKey {
    static let liveValue: Self = {
        let service = RealtimeService()
        return Self(
            fetchTripUpdate: { tripID, source in
                try await service.fetchTripUpdate(tripID: tripID, source: source)
            },
            fetchVehiclePosition: { tripID, source in
                try await service.fetchVehiclePosition(tripID: tripID, source: source)
            },
            fetchAlerts: { source, tripID in
                try await service.fetchAlerts(source: source, tripID: tripID)
            }
        )
    }()
}

extension DependencyValues {
    var realtimeClient: RealtimeClient {
        get { self[RealtimeClient.self] }
        set { self[RealtimeClient.self] = newValue }
    }
}
