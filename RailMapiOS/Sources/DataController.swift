//
//  DataController.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 12/07/2024.
//

import CoreData
import Foundation

class DataController: ObservableObject {
    let container = NSPersistentContainer(name: "RailMap")
    
    @Published var journeys: [Journey] = [Journey]()
    
    init() {
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
    }
    
    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
                print("Data saved to CoreData")
            } catch {
                print("Failed to save data: \(error.localizedDescription)")
            }
        }
    }
    
    // Save a new journey to CoreData
    func saveJourney(newJourney: NewJourneyModel) {
        let context = container.viewContext
        
        let journey = Journey(context: context)
        journey.startDate = newJourney.startDate
        journey.endDate = newJourney.endDate
        journey.headsign = newJourney.headsign
        journey.idVehiculeJourney = newJourney.idVehicleJourney
        journey.company = newJourney.company
        
        for newStop in newJourney.stops {
            let stop = Stop(context: context)
            stop.arrivalTimeUTC = newStop.arrivalTimeUTC
            stop.departureTimeUTC = newStop.departureTimeUTC
            stop.status = newStop.status
            
            if let newStopInfo = newStop.stopInfo {
                let stopInfo = StopInfo(context: context)
                stopInfo.id = newStopInfo.id
                stopInfo.label = newStopInfo.label
                stopInfo.coord = newStopInfo.coord
                stopInfo.adress = newStopInfo.adress
                stopInfo.pickUpAllowed = newStopInfo.pickUpAllowed
                stopInfo.dropOffAllowed = newStopInfo.dropOffAllowed
                stopInfo.skippedStop = newStopInfo.skippedStop
                
                stopInfo.stop = stop
                stop.stopinfo = stopInfo
            }
            
            journey.addToStops(stop)
        }
        
        saveContext()
    }

    func createMockJourneys(context: NSManagedObjectContext) {
        var compagnies = ["Deutsche Bahn", "SNCF", "Eurostar", "Trenitalia", "Renfe"]
        var date = Date()
        
        for i in 1...5 {
            let journey = Journey(context: context)
            journey.id = UUID()
            journey.idVehiculeJourney = "\(String(describing: journey.id))_idVehiculeJourney"
            journey.headsign = "Headsign \(i)"
            journey.archived = false
            journey.company = compagnies.randomElement()
            journey.startDate = generateEndDate(from: date)
            journey.endDate = generateEndDate(from: journey.startDate!)
        }
        do {
            try context.save()
        } catch {
            print("Failed to save mock data: \(error.localizedDescription)")
        }
    }

    func generateEndDate(from startDate: Date) -> Date {
        let calendar = Calendar.current
        
        // Définir les intervalles de temps
        let minInterval: TimeInterval = 30 * 60  // 30 minutes en secondes
        let maxInterval: TimeInterval = 5 * 3600  // 5 heures en secondes
        
        // Générer un intervalle aléatoire entre minInterval et maxInterval
        let randomInterval = TimeInterval.random(in: minInterval...maxInterval)
        
        // Calculer la date de fin
        let endDate = calendar.date(byAdding: .second, value: Int(randomInterval), to: startDate)!
        
        return endDate
    }

}

extension NSPersistentContainer {
    static var preview: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "RailMap")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
}
