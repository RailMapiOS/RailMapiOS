//
//  JourneyDataService.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 21/03/2025.
//


import Foundation

@preconcurrency
protocol JourneyDataServiceProtocol {
    func getDepartureStop(_ journey: Journey) -> Stop?
    func getArrivalStop(_ journey: Journey) -> Stop?
}

class JourneyDataService: JourneyDataServiceProtocol {
    func getDepartureStop(_ journey: Journey) -> Stop? {
        let stop = (journey.stops)?.first { $0.status == "departure" }
        if stop == nil {
            LogManager.error("Departure stop not found for journey \(journey.headsign ?? "unknown")", category: "data", privacy: .private)
        }
        return stop
    }
    
    func getArrivalStop(_ journey: Journey) -> Stop? {
        let stop = (journey.stops)?.first { $0.status == "arrival" }
        if stop == nil {
            LogManager.error("Arrival stop not found for journey \(journey.headsign ?? "unknown")", category: "data", privacy: .private)
        }
        return stop
    }
}
