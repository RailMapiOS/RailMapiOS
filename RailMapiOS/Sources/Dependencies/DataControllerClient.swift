//
//  DataControllerClient.swift
//  RailMapiOS
//
//  Thin TCA adapter for DataService.
//

import CoreLocation
import Dependencies
import DependenciesMacros
import Foundation
import SwiftData

@DependencyClient
struct DataControllerClient {
    var saveJourney: @Sendable (_ journey: NewJourneyModel) async -> Void
    var loadJourneys: @Sendable () async -> [Journey] = { [] }
    var deleteJourney: @Sendable (_ journeyID: UUID) async -> Void
    var deleteAllJourneys: @Sendable () async -> Void
    var saveRouteShape: @Sendable (_ journeyID: UUID, _ coordinates: [CLLocationCoordinate2D], _ source: String) async -> Void
    var getModelContainer: @Sendable () -> ModelContainer? = { nil }
}

extension DataControllerClient: DependencyKey {
    /// Set at app launch — the DataService is owned by the app.
    nonisolated(unsafe) static var shared: DataService?

    static let liveValue = Self(
        saveJourney: { newJourney in
            await MainActor.run { shared?.save(newJourney: newJourney) }
        },
        loadJourneys: {
            await MainActor.run { shared?.loadJourneys() ?? [] }
        },
        deleteJourney: { id in
            await MainActor.run { shared?.deleteJourney(id: id) }
        },
        deleteAllJourneys: {
            await MainActor.run { shared?.deleteAllJourneys() }
        },
        saveRouteShape: { journeyID, coordinates, source in
            await MainActor.run { shared?.saveRouteShape(journeyID: journeyID, coordinates: coordinates, source: source) }
        },
        getModelContainer: { shared?.modelContainer }
    )
}

extension DependencyValues {
    var dataControllerClient: DataControllerClient {
        get { self[DataControllerClient.self] }
        set { self[DataControllerClient.self] = newValue }
    }
}
