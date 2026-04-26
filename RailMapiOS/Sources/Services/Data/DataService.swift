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
        modelContainer = try ModelContainer(for: Journey.self, Stop.self, StopInfos.self)
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
            LogManager.error("Échec du chargement des trajets: \(error.localizedDescription)", category: "swift_data_error")
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
            LogManager.error("Échec de la suppression des trajets: \(error.localizedDescription)", category: "swift_data_error")
        }
    }

    // MARK: - Route shapes

    /// Persists a resolved route shape on the journey.
    func saveRouteShape(journeyID: UUID, coordinates: [CLLocationCoordinate2D], source: String) {
        guard let journey = loadJourneys().first(where: { $0.id == journeyID }) else { return }
        journey.setRouteShape(coordinates: coordinates, source: source)
        save()
    }

    // MARK: - Private

    private func save() {
        do {
            try modelContext.save()
        } catch {
            LogManager.error("Échec de la sauvegarde des données: \(error.localizedDescription)", category: "swift_data_error")
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
