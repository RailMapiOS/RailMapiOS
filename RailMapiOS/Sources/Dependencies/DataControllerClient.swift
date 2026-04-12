//
//  DataControllerClient.swift
//  RailMapiOS
//
//  TCA Dependency wrapping DataController for SwiftData operations.
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
    var deleteAllJourneys: @Sendable () async -> Void
    var saveRouteShape: @Sendable (_ journey: Journey, _ coordinates: [CLLocationCoordinate2D], _ source: String) async -> Void
    var getModelContainer: @Sendable () -> ModelContainer? = { nil }
}

extension DataControllerClient: DependencyKey {
    /// Shared reference set at app launch, before any dependency is resolved.
    nonisolated(unsafe) static var shared: DataController?

    static let liveValue = Self(
        saveJourney: { newJourney in
            await MainActor.run { shared?.saveJourney(newJourney: newJourney) }
        },
        loadJourneys: {
            await MainActor.run {
                shared?.loadJourneys()
                return shared?.journeys ?? []
            }
        },
        deleteAllJourneys: {
            await MainActor.run { shared?.deleteAllJourneys() }
        },
        saveRouteShape: { journey, coordinates, source in
            await MainActor.run {
                journey.setRouteShape(coordinates: coordinates, source: source)
                shared?.saveContext()
            }
        },
        getModelContainer: {
            shared?.modelContainer
        }
    )
}

extension DependencyValues {
    var dataControllerClient: DataControllerClient {
        get { self[DataControllerClient.self] }
        set { self[DataControllerClient.self] = newValue }
    }
}
