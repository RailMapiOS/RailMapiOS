//
//  DataControllerClient.swift
//  RailMapiOS
//
//  TCA Dependency wrapping DataController for SwiftData operations.
//

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
    var modelContainer: @Sendable () -> ModelContainer? = { nil }
}

import CoreLocation

extension DataControllerClient: DependencyKey {
    static let liveValue: Self = {
        // DataController is @MainActor, so we capture it lazily
        let getController: @Sendable () -> DataController = {
            // This will be set from the app entry point
            DataControllerClient._sharedController!
        }

        return Self(
            saveJourney: { newJourney in
                await MainActor.run {
                    getController().saveJourney(newJourney: newJourney)
                }
            },
            loadJourneys: {
                await MainActor.run {
                    getController().loadJourneys()
                    return getController().journeys
                }
            },
            deleteAllJourneys: {
                await MainActor.run {
                    getController().deleteAllJourneys()
                }
            },
            saveRouteShape: { journey, coordinates, source in
                await MainActor.run {
                    journey.setRouteShape(coordinates: coordinates, source: source)
                    getController().saveContext()
                }
            },
            modelContainer: {
                getController().modelContainer
            }
        )
    }()

    /// Set by the app entry point to provide access to the shared DataController.
    @MainActor static var _sharedController: DataController?
}

extension DependencyValues {
    var dataControllerClient: DataControllerClient {
        get { self[DataControllerClient.self] }
        set { self[DataControllerClient.self] = newValue }
    }
}
