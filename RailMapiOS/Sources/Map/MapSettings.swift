//
//  MapSettings.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 28/02/2025.
//

import SwiftUI
import MapKit

/// Gère les paramètres et les données de la carte
///
/// Cette classe est responsable de la gestion des paramètres de la carte,
/// du stockage des trajets et de la génération des routes pour l'affichage.
///
/// ## Fonctionnalités
/// - Stockage des trajets (journeys)
/// - Génération des routes de train pour l'affichage sur la carte
/// - Configuration des paramètres de la carte (type, localisation utilisateur)
class MapSettings: ObservableObject {
    /// Type de carte à afficher
    @Published var mapType: MKMapType = .standard
    
    /// Indique si la position de l'utilisateur doit être affichée
    @Published var showsUserLocation: Bool = true
    
    /// Liste des trajets à afficher sur la carte
    @Published var journeys: [Journey] = []
    
    /// Routes de train générées à partir des trajets
    @Published var trainRoutes: [TrainRoute] = []
    
    // Gestion de la caméra
    @Published var cameraPosition: MapCameraPosition = .automatic
    @Published var selectedRoute: TrainRoute?
    
    /// Initialise une nouvelle instance de MapSettings
    public init() {
        LogManager.info("Initialisation de MapSettings", category: "map")
    }
    
    /// Met à jour les trajets à partir d'une collection FetchedResults
    /// - Parameter journeys: Les trajets à afficher
    public func updateJourneys(from journeys: FetchedResults<Journey>) {
        LogManager.info("Mise à jour des trajets depuis FetchedResults (\(journeys.count) trajets)", category: "map")
        self.journeys = Array(journeys).sorted { $0.startDate! > $1.startDate! }
        generateTrainRoutes()
    }
    
    /// Met à jour les trajets à partir d'un tableau de Journey
    /// - Parameter journeys: Les trajets à afficher
    public func updateJourneys(from journeys: [Journey]) {
        LogManager.info("Mise à jour des trajets depuis un tableau (\(journeys.count) trajets)", category: "map")
        self.journeys = journeys
        generateTrainRoutes()
    }
    
    /// Génère les routes de train à partir des trajets
    private func generateTrainRoutes() {
        LogManager.debug("Génération des routes de train pour \(journeys.count) trajets", category: "map")
        
        let previousRouteCount = self.trainRoutes.count
        
        self.trainRoutes = journeys.compactMap { journey -> TrainRoute? in
            guard let stopSet = journey.stops as? NSSet,
                  var stops = stopSet.allObjects as? [Stop] else {
                LogManager.warning("Impossible d'extraire les arrêts pour le trajet \(journey.headsign ?? "inconnu")", category: "map")
                return nil
            }
            
            stops.sort(by: { ($0.departureTimeUTC ?? $0.arrivalTimeUTC)! < ($1.departureTimeUTC ?? $1.arrivalTimeUTC)! })
            
            guard let departureIndex = stops.firstIndex(where: { $0.status?.lowercased() == "departure" }),
                  let arrivalIndex = stops.lastIndex(where: { $0.status?.lowercased() == "arrival" }),
                  departureIndex < arrivalIndex else {
                LogManager.warning("Structure d'arrêts invalide pour le trajet \(journey.headsign ?? "inconnu")", category: "map")
                return nil
            }
            
            let routeStops = Array(stops[departureIndex...arrivalIndex])
            
            let coordinates = routeStops.compactMap { stop -> CLLocationCoordinate2D? in
                guard let info = stop.stopinfo else {
                    LogManager.warning("Information d'arrêt manquante pour un arrêt du trajet \(journey.headsign ?? "inconnu")", category: "map")
                    return nil
                }
                return CLLocationCoordinate2D(latitude: info.latitude, longitude: info.longitude)
            }
            
            if coordinates.count < 2 {
                LogManager.warning("Pas assez de coordonnées pour créer une route pour le trajet \(journey.headsign ?? "inconnu")", category: "map")
                return nil
            }
            
            LogManager.debug("Route créée pour le trajet \(journey.headsign ?? "inconnu") avec \(coordinates.count) points", category: "map")
            return TrainRoute(coordinates: coordinates)
        }
        updateCameraToShowAllRoutes()
        LogManager.info("\(self.trainRoutes.count) routes générées (précédemment: \(previousRouteCount))", category: "map")
    }
    
    /// Sélectionne une route spécifique et centre la carte sur celle-ci
    func selectRoute(_ route: TrainRoute?) {
        if let route = route {
            LogManager.info("Sélection de la route: \(route.id)", category: "map")
            selectedRoute = route
            
            if !route.coordinates.isEmpty {
                LogManager.debug("Mise à jour de la position de la caméra pour la route sélectionnée", category: "map")
                withAnimation(.easeInOut(duration: 1.5)) {
                    cameraPosition = .region(MKCoordinateRegion(
                        coordinates: route.coordinates,
                        padding: 250
                    ))
                }
            }
        } else {
            LogManager.info("Désélection de la route", category: "map")
            selectedRoute = nil
            updateCameraToShowAllRoutes()
        }
    }
    
    func clearRouteSelection() {
        LogManager.info("Désélection de la route active", category: "map")
        selectedRoute = nil
        updateCameraToShowAllRoutes()
    }
    
    /// Met à jour la position de la caméra pour montrer toutes les routes
    func updateCameraToShowAllRoutes() {
        if !trainRoutes.isEmpty {
            LogManager.debug("Mise à jour de la position de la caméra pour montrer toutes les routes", category: "map")
            
            let allCoordinates = trainRoutes.flatMap { $0.coordinates }
            
            if !allCoordinates.isEmpty {
                withAnimation(.easeInOut(duration: 1.5)) {
                    cameraPosition = .region(MKCoordinateRegion(
                        coordinates: allCoordinates,
                        padding: 150
                    ))
                }
            }
        }
    }

}

/// Représente une route de train sur la carte
///
/// Cette structure contient les coordonnées géographiques qui définissent
/// le tracé d'un trajet ferroviaire sur la carte.
public struct TrainRoute: Identifiable, Equatable {
    
    /// Identifiant unique de la route
    public let id = UUID()
    
    /// Coordonnées géographiques qui composent la route
    let coordinates: [CLLocationCoordinate2D]
    
    public static func == (lhs: TrainRoute, rhs: TrainRoute) -> Bool {
        return lhs.id == rhs.id &&
               lhs.coordinates.first == rhs.coordinates.first &&
               lhs.coordinates.last == rhs.coordinates.last
    }
}

#if swift(>=6.0)
extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
#else
extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
#endif


extension MKCoordinateRegion {
    init(coordinates: [CLLocationCoordinate2D], padding: CGFloat = 0) {
        var minLat = coordinates.first?.latitude ?? 0
        var maxLat = minLat
        var minLon = coordinates.first?.longitude ?? 0
        var maxLon = minLon
        
        for coordinate in coordinates {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLon = min(minLon, coordinate.longitude)
            maxLon = max(maxLon, coordinate.longitude)
        }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.2,
            longitudeDelta: (maxLon - minLon) * 1.2
        )
        
        self.init(center: center, span: span)
    }
}
