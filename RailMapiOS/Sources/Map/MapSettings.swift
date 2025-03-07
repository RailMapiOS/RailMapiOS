//
//  MapSettings.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 28/02/2025.
//

import SwiftUI
import MapKit

class MapSettings: ObservableObject {
    @Published var mapType: MKMapType = .standard
    @Published var showsUserLocation: Bool = true
    
    @Published var journeys: [Journey] = []
    @Published var trainRoutes: [TrainRoute] = []
    
    
    public init() {}
    
    public func updateJourneys(from journeys: FetchedResults<Journey>) {
        self.journeys = Array(journeys).sorted { $0.startDate! > $1.startDate! }
        generateTrainRoutes()
    }
    
    public func updateJourneys(from journeys: [Journey]) {
        self.journeys = journeys
        generateTrainRoutes()
    }
    
    private func generateTrainRoutes() {
        self.trainRoutes = journeys.compactMap { journey -> TrainRoute? in
            guard let stopSet = journey.stops as? NSSet,
                  var stops = stopSet.allObjects as? [Stop] else {
                return nil
            }
            
            stops.sort(by: { ($0.departureTimeUTC ?? $0.arrivalTimeUTC)! < ($1.departureTimeUTC ?? $1.arrivalTimeUTC)! })
            
            guard let departureIndex = stops.firstIndex(where: { $0.status?.lowercased() == "departure" }),
                  let arrivalIndex = stops.lastIndex(where: { $0.status?.lowercased() == "arrival" }),
                  departureIndex < arrivalIndex else {
                return nil
            }
            
            let routeStops = Array(stops[departureIndex...arrivalIndex])
            
            let coordinates = routeStops.compactMap { stop -> CLLocationCoordinate2D? in
                guard let info = stop.stopinfo else { return nil }
                return CLLocationCoordinate2D(latitude: info.latitude, longitude: info.longitude)
            }
            
            return TrainRoute(coordinates: coordinates)
        }
    }
}

public struct TrainRoute: Identifiable {
    public let id = UUID()
    let coordinates: [CLLocationCoordinate2D]
}
