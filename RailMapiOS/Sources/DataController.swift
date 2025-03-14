//
//  DataController.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 12/07/2024.
//

import CoreData
import Foundation

/// Contrôleur de données responsable de la gestion des opérations CoreData
///
/// Cette classe gère le chargement, la sauvegarde et la manipulation des données
/// persistantes de l'application, notamment les trajets (journeys).
class DataController: ObservableObject {
    let container = NSPersistentContainer(name: "RailMap")
    
    @Published var journeys: [Journey] = []
    
    private var mapSettings: MapSettings?
    
    init() {
        LogManager.info("Initialisation du DataController", category: "core_data")
        container.loadPersistentStores { description, error in
            if let error = error {
                LogManager.error("Échec du chargement de Core Data: \(error.localizedDescription)", category: "core_data_error")
            } else {
                LogManager.info("Core Data chargé avec succès", category: "core_data")
            }
        }
        
        loadJourneys()
    }
    
    /// Connecte les paramètres de carte au contrôleur de données
    /// - Parameter mapSettings: L'instance de MapSettings à connecter
    func connectMapSettings(_ mapSettings: MapSettings) {
        LogManager.debug("Connexion des paramètres de carte au DataController", category: "core_data")
        self.mapSettings = mapSettings
        updateMapSettings()
    }
    
    /// Charge tous les trajets depuis CoreData
    func loadJourneys() {
        LogManager.info("Chargement des trajets depuis CoreData", category: "core_data")
        let request: NSFetchRequest<Journey> = Journey.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Journey.startDate, ascending: true)]
        
        let context = container.viewContext
        
        do {
            journeys = try context.fetch(request)
            LogManager.info("\(journeys.count) trajets chargés avec succès", category: "core_data")
        } catch {
            LogManager.error("Échec du chargement des trajets: \(error.localizedDescription)", category: "core_data_error")
        }
    }
    
    /// Met à jour les paramètres de carte avec les trajets actuels
    private func updateMapSettings() {
        guard let mapSettings = mapSettings else {
            LogManager.warning("Tentative de mise à jour des paramètres de carte sans connexion établie", category: "core_data")
            return
        }
        LogManager.debug("Mise à jour des paramètres de carte avec \(journeys.count) trajets", category: "core_data")
        mapSettings.updateJourneys(from: self.journeys)
    }
    
    /// Sauvegarde le contexte CoreData si des modifications ont été effectuées
    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
                LogManager.info("Données sauvegardées dans CoreData", category: "core_data")
                loadJourneys()
            } catch {
                LogManager.error("Échec de la sauvegarde des données: \(error.localizedDescription)", category: "core_data_error")
            }
        } else {
            LogManager.debug("Aucune modification à sauvegarder dans CoreData", category: "core_data")
        }
    }
    
    /// Sauvegarde un nouveau trajet dans CoreData
    /// - Parameter newJourney: Le modèle du nouveau trajet à sauvegarder
    func saveJourney(newJourney: NewJourneyModel) {
        LogManager.info("Sauvegarde d'un nouveau trajet: \(newJourney.headsign ?? "sans destination")", category: "core_data")
        let context = container.viewContext
        
        let journey = Journey(context: context)
        journey.startDate = newJourney.startDate
        journey.endDate = newJourney.endDate
        journey.headsign = newJourney.headsign
        journey.idVehiculeJourney = newJourney.idVehicleJourney
        journey.company = newJourney.company
        
        LogManager.debug("Création de \(newJourney.stops.count) arrêts pour le trajet", category: "core_data")
        for newStop in newJourney.stops {
            let stop = Stop(context: context)
            stop.arrivalTimeUTC = newStop.arrivalTimeUTC
            stop.departureTimeUTC = newStop.departureTimeUTC
            stop.status = newStop.status
            
            if let newStopInfo = newStop.stopInfo {
                let stopInfo = StopInfo(context: context)
                stopInfo.id = newStopInfo.id
                stopInfo.label = newStopInfo.label
                stopInfo.latitude = newStopInfo.latitude
                stopInfo.longitude = newStopInfo.longitude
                stopInfo.adress = newStopInfo.adress
                stopInfo.pickUpAllowed = newStopInfo.pickUpAllowed
                stopInfo.dropOffAllowed = newStopInfo.dropOffAllowed
                stopInfo.skippedStop = newStopInfo.skippedStop
                
                stop.stopinfo = stopInfo
                LogManager.debug("Arrêt créé: \(newStopInfo.label ?? "sans nom")", category: "core_data")
            }
            
            journey.addToStops(stop)
        }
        
        saveContext()
    }
    
    /// Crée des trajets fictifs pour les tests et le développement
    /// - Parameter context: Le contexte CoreData dans lequel créer les trajets
    func createMockJourneys(context: NSManagedObjectContext) {
        LogManager.info("Création de trajets fictifs pour les tests", category: "core_data")
        let compagnies = ["Deutsche Bahn", "SNCF", "Eurostar", "TER", "Trenitalia", "Renfe"]
        var date = Date()
        
        for indexMock in 1...5 {
            let journey = Journey(context: context)
            journey.id = UUID()
            journey.idVehiculeJourney = "\(journey.id?.uuidString ?? UUID().uuidString)_idVehiculeJourney"
            journey.headsign = "Headsign \(indexMock)"
            journey.archived = false
            journey.company = compagnies.randomElement()
            journey.startDate = generateEndDate(from: date)
            journey.endDate = generateEndDate(from: journey.startDate!)
            
            LogManager.debug("Création du trajet fictif #\(indexMock): \(journey.headsign ?? "")", category: "core_data")
            
            // Créer les objets Stop
            let departureStop = Stop(context: context)
            departureStop.arrivalTimeUTC = journey.startDate
            departureStop.departureTimeUTC = journey.startDate
            departureStop.status = "departure"
            
            let departureStopInfo = StopInfo(context: context)
            departureStopInfo.label = "Gare de Lyon"
            departureStopInfo.dropOffAllowed = true
            departureStopInfo.pickUpAllowed = true
            departureStopInfo.skippedStop = false
            departureStop.stopinfo = departureStopInfo
            
            let arrivalStop = Stop(context: context)
            arrivalStop.arrivalTimeUTC = journey.endDate
            arrivalStop.departureTimeUTC = journey.endDate
            arrivalStop.status = "arrival"
            
            let arrivalStopInfo = StopInfo(context: context)
            arrivalStopInfo.label = "Gare de Perpignan"
            arrivalStopInfo.dropOffAllowed = true
            arrivalStopInfo.pickUpAllowed = true
            arrivalStopInfo.skippedStop = false
            arrivalStop.stopinfo = arrivalStopInfo
            
            // Ajouter les arrêts au voyage
            journey.addToStops(departureStop)
            journey.addToStops(arrivalStop)
            
            LogManager.debug("Arrêts ajoutés au trajet fictif #\(indexMock)", category: "core_data")
        }
        do {
            try context.save()
            LogManager.info("5 trajets fictifs créés et sauvegardés avec succès", category: "core_data")
        } catch {
            LogManager.error("Échec de la sauvegarde des données fictives: \(error.localizedDescription)", category: "core_data_error")
        }
    }
    
    /// Génère une date de fin aléatoire à partir d'une date de début
    /// - Parameter startDate: La date de début
    /// - Returns: Une date de fin générée aléatoirement
    func generateEndDate(from startDate: Date) -> Date {
        let calendar = Calendar.current
        
        // Définir les intervalles de temps
        let minInterval: TimeInterval = 30 * 60  // 30 minutes en secondes
        let maxInterval: TimeInterval = 5 * 3600  // 5 heures en secondes
        
        // Générer un intervalle aléatoire entre minInterval et maxInterval
        let randomInterval = TimeInterval.random(in: minInterval...maxInterval)
        
        // Calculer la date de fin
        let endDate = calendar.date(byAdding: .second, value: Int(randomInterval), to: startDate)!
        
        LogManager.debug("Date de fin générée: \(endDate) (intervalle: \(Int(randomInterval/60)) minutes)", category: "core_data")
        return endDate
    }
    
    /// Supprime tous les objets d'une entité spécifiée
    /// - Parameters:
    ///   - entityName: Le nom de l'entité à supprimer
    ///   - context: Le contexte CoreData dans lequel effectuer la suppression
    func deleteAllObjects(of entityName: String, context: NSManagedObjectContext) {
        LogManager.warning("Suppression de tous les objets de l'entité \(entityName)", category: "core_data")
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
            LogManager.info("Tous les objets de l'entité \(entityName) ont été supprimés", category: "core_data")
            loadJourneys()
        } catch {
            LogManager.error("Échec de la suppression des objets: \(error.localizedDescription)", category: "core_data_error")
        }
    }
}

extension NSPersistentContainer {
    /// Conteneur persistant pour l'aperçu et les tests
    static var preview: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "RailMap")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                LogManager.error("Erreur non résolue lors du chargement du conteneur de prévisualisation: \(error), \(error.userInfo)", category: "core_data_error")
                fatalError("Unresolved error \(error), \(error.userInfo)")
            } else {
                LogManager.debug("Conteneur de prévisualisation chargé avec succès", category: "core_data")
            }
        }
        return container
    }()
}
