//
// DataController.swift
// RailMapiOS
//
// Created by Jérémie Patot on 12/07/2024.
//

import SwiftData
import Foundation

/// Contrôleur de données responsable de la gestion des opérations SwiftData
@MainActor
class DataController: ObservableObject {
    let modelContainer: ModelContainer
    private let modelContext: ModelContext

    @Published var journeys: [Journey] = []

    init() {
        do {
            modelContainer = try ModelContainer(for: Journey.self, Stop.self, StopInfos.self)
            modelContext = ModelContext(modelContainer)
        } catch {
            LogManager.error("Échec de l'initialisation de SwiftData: \(error.localizedDescription)", category: "swift_data_error")
            fatalError("Impossible d'initialiser SwiftData: \(error)")
        }

        loadJourneys()
    }

    /// Charge tous les trajets depuis SwiftData
    func loadJourneys() {
        let descriptor = FetchDescriptor<Journey>(
            sortBy: [SortDescriptor(\.startDate, order: .forward)]
        )

        do {
            journeys = try modelContext.fetch(descriptor)
        } catch {
            LogManager.error("Échec du chargement des trajets: \(error.localizedDescription)", category: "swift_data_error")
        }
    }

    /// Sauvegarde le contexte SwiftData si des modifications ont été effectuées
    func saveContext() {
        do {
            try modelContext.save()
            loadJourneys()
        } catch {
            LogManager.error("Échec de la sauvegarde des données: \(error.localizedDescription)", category: "swift_data_error")
        }
    }

    /// Sauvegarde un nouveau trajet dans SwiftData
    func saveJourney(newJourney: NewJourneyModel) {
        let journey = Journey()
        journey.id = UUID()
        journey.startDate = newJourney.startDate
        journey.endDate = newJourney.endDate
        journey.headsign = newJourney.headsign
        journey.idVehiculeJourney = newJourney.idVehicleJourney
        journey.company = newJourney.company
        journey.archived = false
        journey.stops = []

        for newStop in newJourney.stops {
            let stop = Stop()
            stop.arrivalTimeUTC = newStop.arrivalTimeUTC
            stop.departureTimeUTC = newStop.departureTimeUTC
            stop.status = newStop.status
            stop.journey = journey

            if let newStopInfo = newStop.stopInfo {
                let stopInfo = StopInfos()
                stopInfo.id = newStopInfo.id
                stopInfo.label = newStopInfo.label
                stopInfo.latitude = newStopInfo.latitude
                stopInfo.longitude = newStopInfo.longitude
                stopInfo.adress = newStopInfo.adress
                stopInfo.pickUpAllowed = newStopInfo.pickUpAllowed
                stopInfo.dropOffAllowed = newStopInfo.dropOffAllowed
                stopInfo.skippedStop = newStopInfo.skippedStop
                stopInfo.stop = stop

                stop.stopinfo = stopInfo
                modelContext.insert(stopInfo)
            }

            journey.stops?.append(stop)
            modelContext.insert(stop)
        }

        modelContext.insert(journey)
        saveContext()
    }

    /// Supprime tous les trajets
    func deleteAllJourneys() {
        do {
            try modelContext.delete(model: Journey.self)
            saveContext()
        } catch {
            LogManager.error("Échec de la suppression des trajets: \(error.localizedDescription)", category: "swift_data_error")
        }
    }
}
