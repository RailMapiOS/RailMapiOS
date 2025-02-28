//
//  MapView.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 28/02/2025.
//

import SwiftUI
import MapKit
import Combine

struct MapView: View {
    @Binding var sheetSize: PresentationDetent
    let journeys: FetchedResults<Journey>
    
    private var trainRoutes: [TrainRoute] {
        journeys.compactMap { journey -> TrainRoute? in
            guard let stopSet = journey.stops as? NSSet,
                  var stops = stopSet.allObjects as? [Stop] else {
                return nil
            }
            
            // 1. Tri chronologique des arrêts
            stops.sort(by: { ($0.departureTimeUTC ?? $0.arrivalTimeUTC)! < ($1.departureTimeUTC ?? $1.arrivalTimeUTC)! })
            
            // 2. Trouver les indices de départ et d'arrivée
            guard let departureIndex = stops.firstIndex(where: { $0.status?.lowercased() == "departure" }),
                  let arrivalIndex = stops.lastIndex(where: { $0.status?.lowercased() == "arrival" }),
                  departureIndex < arrivalIndex else {
                return nil
            }
            
            // 3. Extraire le segment du trajet concerné
            let routeStops = Array(stops[departureIndex...arrivalIndex])
            
            // 4. Convertir en coordonnées
            let coordinates = routeStops.compactMap { stop -> CLLocationCoordinate2D? in
                guard let info = stop.stopinfo else { return nil }
                return CLLocationCoordinate2D(latitude: info.latitude, longitude: info.longitude)
            }
            
            return TrainRoute(coordinates: coordinates)
        }
    }
    
    init(sheetSize: Binding<PresentationDetent>, journeys: FetchedResults<Journey>) {
        self._sheetSize = sheetSize
        self.journeys = journeys
    }
    
    var body: some View {
        Map {
            if !trainRoutes.isEmpty {
                ForEach(trainRoutes) { route in
                    // Ligne principale du trajet
                    MapPolyline(coordinates: route.coordinates)
                        .stroke(.blue, lineWidth: 3)
                    
                    // Marqueurs pour toutes les gares
                    ForEach(route.coordinates.indices, id: \.self) { index in
                        let coord = route.coordinates[index]
                        let isDeparture = index == 0
                        let isArrival = index == route.coordinates.count - 1
                        
                        if isDeparture {
                            Annotation("", coordinate: coord) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 7))
                                    .foregroundStyle(.blue)
                            }
                        }
                        
                        if isArrival {
                            Annotation("", coordinate: coord) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 7))
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
        }
        .mapStyle(.standard)
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear
                .frame(height: getBottomSheetHeight())
        }
    }
    
    private func getBottomSheetHeight() -> CGFloat {
        switch sheetSize {
        default:
            return UIScreen.main.bounds.height * 0.3
        }
    }
}

    struct TrainRoute: Identifiable {
        let id = UUID()
        let coordinates: [CLLocationCoordinate2D]
    }
