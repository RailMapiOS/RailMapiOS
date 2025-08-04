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
    
    @Published var journeys: [JourneySD] = []
    private var mapSettings: MapSettings?
    
    init() {
        LogManager.info("Initialisation du DataController avec SwiftData", category: "swift_data")
        
        do {
            modelContainer = try ModelContainer(for: JourneySD.self, StopSD.self, StopInfosSD.self, CoordinatesSD.self)
            modelContext = ModelContext(modelContainer)
            LogManager.info("SwiftData initialisé avec succès", category: "swift_data")
        } catch {
            LogManager.error("Échec de l'initialisation de SwiftData: \(error.localizedDescription)", category: "swift_data_error")
            fatalError("Impossible d'initialiser SwiftData: \(error)")
        }
        
        loadJourneys()
    }
    
    /// Connecte les paramètres de carte au contrôleur de données
    func connectMapSettings(_ mapSettings: MapSettings) {
        LogManager.debug("Connexion des paramètres de carte au DataController", category: "swift_data")
        self.mapSettings = mapSettings
        updateMapSettings()
    }
    
    /// Charge tous les trajets depuis SwiftData
    func loadJourneys() {
        LogManager.info("Chargement des trajets depuis SwiftData", category: "swift_data")
        
        let descriptor = FetchDescriptor<JourneySD>(
            sortBy: [SortDescriptor(\.startDate, order: .forward)]
        )
        
        do {
            journeys = try modelContext.fetch(descriptor)
            LogManager.info("\(journeys.count) trajets chargés avec succès", category: "swift_data")
            updateMapSettings()
        } catch {
            LogManager.error("Échec du chargement des trajets: \(error.localizedDescription)", category: "swift_data_error")
        }
    }
    
    /// Met à jour les paramètres de carte avec les trajets actuels
    private func updateMapSettings() {
        guard let mapSettings = mapSettings else {
            LogManager.warning("Tentative de mise à jour des paramètres de carte sans connexion établie", category: "swift_data")
            return
        }
        
        LogManager.debug("Mise à jour des paramètres de carte avec \(journeys.count) trajets", category: "swift_data")
        mapSettings.updateJourneys(from: self.journeys)
    }
    
    /// Sauvegarde le contexte SwiftData si des modifications ont été effectuées
    func saveContext() {
        do {
            try modelContext.save()
            LogManager.info("Données sauvegardées dans SwiftData", category: "swift_data")
            loadJourneys()
        } catch {
            LogManager.error("Échec de la sauvegarde des données: \(error.localizedDescription)", category: "swift_data_error")
        }
    }
    
    /// Sauvegarde un nouveau trajet dans SwiftData
    func saveJourney(newJourney: NewJourneyModel) {
        LogManager.info("Sauvegarde d'un nouveau trajet: \(newJourney.headsign)", category: "swift_data")
        
        let journey = JourneySD()
        journey.id = UUID()
        journey.startDate = newJourney.startDate
        journey.endDate = newJourney.endDate
        journey.headsign = newJourney.headsign
        journey.idVehiculeJourney = newJourney.idVehicleJourney
        journey.company = newJourney.company
        journey.archived = false
        journey.stops = []
        
        LogManager.debug("Création de \(newJourney.stops.count) arrêts pour le trajet", category: "swift_data")
        
        for newStop in newJourney.stops {
            let stop = StopSD()
            stop.arrivalTimeUTC = newStop.arrivalTimeUTC
            stop.departureTimeUTC = newStop.departureTimeUTC
            stop.status = newStop.status
            stop.journey = journey
            
            if let newStopInfo = newStop.stopInfo {
                let stopInfo = StopInfosSD()
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
                LogManager.debug("Arrêt créé: \(newStopInfo.label)", category: "swift_data")
            }
            
            journey.stops?.append(stop)
            modelContext.insert(stop)
        }
        
        modelContext.insert(journey)
        saveContext()
    }
    
    /// Crée des trajets fictifs pour les tests et le développement
    func createMockJourneys() {
        LogManager.info("Création de trajets fictifs pour les tests", category: "swift_data")
        
        let compagnies = ["Deutsche Bahn", "SNCF", "Eurostar", "TER", "Trenitalia", "Renfe"]
        var date = Date()
        
        for indexMock in 1...5 {
            let startDate = generateEndDate(from: date)
            let endDate = generateEndDate(from: startDate)
            
            let journey = JourneySD()
            journey.id = UUID()
            journey.startDate = startDate
            journey.endDate = endDate
            journey.headsign = "Headsign \(indexMock)"
            journey.idVehiculeJourney = "\(UUID().uuidString)_idVehiculeJourney"
            journey.company = compagnies.randomElement() ?? "SNCF"
            journey.archived = false
            journey.stops = []
            
            LogManager.debug("Création du trajet fictif #\(indexMock): \(journey.headsign ?? "")", category: "swift_data")
            
            // Créer l'arrêt de départ
            let departureStopInfo = StopInfosSD()
            departureStopInfo.id = UUID().uuidString
            departureStopInfo.label = "Gare de Lyon"
            departureStopInfo.latitude = 48.8444
            departureStopInfo.longitude = 2.3732
            departureStopInfo.adress = "Place Louis Armand, 75012 Paris"
            departureStopInfo.pickUpAllowed = true
            departureStopInfo.dropOffAllowed = true
            departureStopInfo.skippedStop = false
            
            let departureStop = StopSD()
            departureStop.arrivalTimeUTC = startDate
            departureStop.departureTimeUTC = startDate
            departureStop.status = "departure"
            departureStop.journey = journey
            departureStop.stopinfo = departureStopInfo
            departureStopInfo.stop = departureStop
            
            // Créer l'arrêt d'arrivée
            let arrivalStopInfo = StopInfosSD()
            arrivalStopInfo.id = UUID().uuidString
            arrivalStopInfo.label = "Gare de Perpignan"
            arrivalStopInfo.latitude = 42.6975
            arrivalStopInfo.longitude = 2.8808
            arrivalStopInfo.adress = "Boulevard Saint-Assiscle, 66000 Perpignan"
            arrivalStopInfo.pickUpAllowed = true
            arrivalStopInfo.dropOffAllowed = true
            arrivalStopInfo.skippedStop = false
            
            let arrivalStop = StopSD()
            arrivalStop.arrivalTimeUTC = endDate
            arrivalStop.departureTimeUTC = endDate
            arrivalStop.status = "arrival"
            arrivalStop.journey = journey
            arrivalStop.stopinfo = arrivalStopInfo
            arrivalStopInfo.stop = arrivalStop
            
            journey.stops = [departureStop, arrivalStop]
            
            // Insérer tous les objets dans le contexte
            modelContext.insert(journey)
            modelContext.insert(departureStop)
            modelContext.insert(arrivalStop)
            modelContext.insert(departureStopInfo)
            modelContext.insert(arrivalStopInfo)
            
            LogManager.debug("Arrêts ajoutés au trajet fictif #\(indexMock)", category: "swift_data")
            date = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? Date()
        }
        
        saveContext()
        LogManager.info("5 trajets fictifs créés et sauvegardés avec succès", category: "swift_data")
    }
    
    /// Génère une date de fin aléatoire à partir d'une date de début
    func generateEndDate(from startDate: Date) -> Date {
        let calendar = Calendar.current
        let minInterval: TimeInterval = 30 * 60 // 30 minutes
        let maxInterval: TimeInterval = 5 * 3600 // 5 heures
        let randomInterval = TimeInterval.random(in: minInterval...maxInterval)
        let endDate = calendar.date(byAdding: .second, value: Int(randomInterval), to: startDate)!
        
        LogManager.debug("Date de fin générée: \(endDate) (intervalle: \(Int(randomInterval/60)) minutes)", category: "swift_data")
        return endDate
    }
    
    /// Supprime tous les trajets
    func deleteAllJourneys() {
        LogManager.warning("Suppression de tous les trajets", category: "swift_data")
        
        do {
            try modelContext.delete(model: JourneySD.self)
            saveContext()
            LogManager.info("Tous les trajets ont été supprimés", category: "swift_data")
        } catch {
            LogManager.error("Échec de la suppression des trajets: \(error.localizedDescription)", category: "swift_data_error")
        }
    }
}
