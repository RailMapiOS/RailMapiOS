//
//  DataService.swift
//  RailMapiOS
//
//  Pure business logic service for SwiftData operations.
//  Owns the ModelContainer/ModelContext lifecycle.
//

import CoreLocation
import Foundation
import SwiftData

/// Manages SwiftData persistence for journeys, stops, and stop infos.
/// Must be used on @MainActor since SwiftData is main-actor bound.
@MainActor
final class DataService {
    let modelContainer: ModelContainer
    private let modelContext: ModelContext

    init() throws {
        // CloudKit sync is only enabled once the user has signed in through the
        // iCloud / Apple SSO flow (see `SignInFeature`). Until then — and on
        // simulators or devices with no iCloud account — the store stays
        // local-only. This avoids the `CKAccountStatusNoAccount` setup error at
        // launch and removes the CloudKit setup latency that delayed first render.
        let configuration = ModelConfiguration(
            cloudKitDatabase: UserStorage.shared.isLoggedIn() ? .automatic : .none
        )
        modelContainer = try ModelContainer(
            for: Journey.self, Stop.self, StopInfos.self,
            configurations: configuration
        )
        modelContext = ModelContext(modelContainer)
    }

    // MARK: - Journeys

    /// Loads all journeys sorted by start date.
    func loadJourneys() -> [Journey] {
        let descriptor = FetchDescriptor<Journey>(
            sortBy: [SortDescriptor(\.startDate, order: .forward)]
        )
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            LogManager.error("Failed to load journeys: \(error.localizedDescription)", category: "swift_data_error")
            return []
        }
    }

    /// Saves a new journey from a `NewJourneyModel` (transactional).
    func save(newJourney: NewJourneyModel) {
        let journey = makeJourney(from: newJourney)
        modelContext.insert(journey)
        save()
    }

    /// Deletes a single journey by ID.
    func deleteJourney(id: UUID) {
        guard let journey = loadJourneys().first(where: { $0.id == id }) else { return }
        modelContext.delete(journey)
        save()
    }

    /// Deletes all journeys.
    func deleteAllJourneys() {
        do {
            try modelContext.delete(model: Journey.self)
            save()
        } catch {
            LogManager.error("Failed to delete journeys: \(error.localizedDescription)", category: "swift_data_error")
        }
    }

    // MARK: - Route shapes

    /// Persists a resolved route shape on the journey.
    func saveRouteShape(journeyID: UUID, coordinates: [CLLocationCoordinate2D], source: String) {
        guard let journey = loadJourneys().first(where: { $0.id == journeyID }) else { return }
        journey.setRouteShape(coordinates: coordinates, source: source)
        save()
    }

    /// Persists the user's choice to dismiss the refund-eligibility banner
    /// on a specific journey. Survives app relaunches.
    func setRefundBannerDismissed(journeyID: UUID, dismissed: Bool) {
        guard let journey = loadJourneys().first(where: { $0.id == journeyID }) else { return }
        journey.refundBannerDismissed = dismissed
        save()
    }

    // MARK: - Private

    private func save() {
        do {
            try modelContext.save()
        } catch {
            LogManager.error("Failed to save data: \(error.localizedDescription)", category: "swift_data_error")
        }
    }

    private func makeJourney(from model: NewJourneyModel) -> Journey {
        let journey = Journey()
        journey.id = UUID()
        journey.startDate = model.startDate
        journey.endDate = model.endDate
        journey.headsign = model.headsign
        journey.idVehiculeJourney = model.idVehicleJourney
        journey.company = model.company
        journey.archived = false
        journey.stops = []

        for newStop in model.stops {
            let stop = Stop()
            stop.arrivalTimeUTC = newStop.arrivalTimeUTC
            stop.departureTimeUTC = newStop.departureTimeUTC
            stop.status = newStop.status
            stop.journey = journey

            if let info = newStop.stopInfo {
                let stopInfo = StopInfos()
                stopInfo.id = info.id
                stopInfo.label = info.label
                stopInfo.latitude = info.latitude
                stopInfo.longitude = info.longitude
                stopInfo.adress = info.adress
                stopInfo.pickUpAllowed = info.pickUpAllowed
                stopInfo.dropOffAllowed = info.dropOffAllowed
                stopInfo.skippedStop = info.skippedStop
                stopInfo.stop = stop
                stop.stopinfo = stopInfo
                modelContext.insert(stopInfo)
            }

            journey.stops?.append(stop)
            modelContext.insert(stop)
        }
        return journey
    }
}
