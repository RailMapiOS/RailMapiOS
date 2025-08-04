//
//  JourneyDataService.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 21/03/2025.
//


import Foundation
import CoreData

@preconcurrency
protocol JourneyDataServiceProtocol {
    func getDepartureStop(_ journey: JourneySD) -> StopSD?
    func getArrivalStop(_ journey: JourneySD) -> StopSD?
}

class JourneyDataService: JourneyDataServiceProtocol {
    func getDepartureStop(_ journey: JourneySD) -> StopSD? {
        let stop = (journey.stops)?.first { $0.status == "departure" }
        if stop == nil {
            LogManager.error("Arrêt de départ non trouvé pour le trajet \(journey.headsign ?? "inconnu")", category: "data", privacy: .private)
        }
        return stop
    }
    
    func getArrivalStop(_ journey: JourneySD) -> StopSD? {
        let stop = (journey.stops)?.first { $0.status == "arrival" }
        if stop == nil {
            LogManager.error("Arrêt d'arrivée non trouvé pour le trajet \(journey.headsign ?? "inconnu")", category: "data", privacy: .private)
        }
        return stop
    }
}
