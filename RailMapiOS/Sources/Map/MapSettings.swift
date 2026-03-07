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
    public init() {}
    
    /// Met à jour les trajets à partir d'une collection FetchedResults
    /// - Parameter journeys: Les trajets à afficher
    public func updateJourneys(from journeys: [Journey]) {
        
        // Trier les trajets par date de départ (gestion des optionnels)
        self.journeys = journeys.sorted { journey1, journey2 in
            guard let date1 = journey1.startDate, let date2 = journey2.startDate else {
                return false
            }
            return date1 > date2
        }
        
        generateTrainRoutes()
    }
    
    /// Génère les routes de train à partir des trajets
    private func generateTrainRoutes() {
        self.trainRoutes = journeys.compactMap { journey -> TrainRoute? in
            guard let stops = journey.stops, !stops.isEmpty else {
                LogManager.warning("Aucun arrêt trouvé pour le trajet \(journey.headsign ?? "inconnu")", category: "map")
                return nil
            }
            
            // Trier les arrêts par heure de départ/arrivée
            let sortedStops = stops.sorted { stop1, stop2 in
                let time1 = stop1.departureTimeUTC ?? stop1.arrivalTimeUTC ?? Date.distantPast
                let time2 = stop2.departureTimeUTC ?? stop2.arrivalTimeUTC ?? Date.distantPast
                return time1 < time2
            }
            
            // Trouver les indices de départ et d'arrivée
            guard let departureIndex = sortedStops.firstIndex(where: { $0.status?.lowercased() == "departure" }),
                  let arrivalIndex = sortedStops.lastIndex(where: { $0.status?.lowercased() == "arrival" }),
                  departureIndex <= arrivalIndex else {
                LogManager.warning("Structure d'arrêts invalide pour le trajet \(journey.headsign ?? "inconnu")", category: "map")
                return nil
            }
            
            // Extraire les arrêts de la route
            let routeStops = Array(sortedStops[departureIndex...arrivalIndex])
            
            // Convertir en coordonnées
            let coordinates = routeStops.compactMap { stop -> CLLocationCoordinate2D? in
                guard let stopInfo = stop.stopinfo,
                      let latitude = stopInfo.latitude,
                      let longitude = stopInfo.longitude else {
                    LogManager.warning("Information de géolocalisation manquante pour un arrêt du trajet \(journey.headsign ?? "inconnu")", category: "map")
                    return nil
                }
                
                return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            }
            
            guard coordinates.count >= 2 else {
                LogManager.warning("Pas assez de coordonnées pour créer une route pour le trajet \(journey.headsign ?? "inconnu")", category: "map")
                return nil
            }
            
            return TrainRoute(coordinates: coordinates, company: journey.company)
        }
        updateCameraToShowAllRoutes()
    }

    /// Sélectionne une route spécifique et centre la carte sur celle-ci
    func selectRoute(_ route: TrainRoute?) {
        if let route = route {
            selectedRoute = route
            if !route.coordinates.isEmpty {
                withAnimation(.easeInOut(duration: 1.5)) {
                    cameraPosition = .region(MKCoordinateRegion(
                        coordinates: route.coordinates,
                        padding: 250
                    ))
                }
            }
        } else {
            selectedRoute = nil
            updateCameraToShowAllRoutes()
        }
    }

    func clearRouteSelection() {
        selectedRoute = nil
        updateCameraToShowAllRoutes()
    }

    /// Met à jour la position de la caméra pour montrer toutes les routes
    func updateCameraToShowAllRoutes() {
        guard !trainRoutes.isEmpty else { return }
        let allCoordinates = trainRoutes.flatMap { $0.coordinates }
        
        guard !allCoordinates.isEmpty else { return }
        
        withAnimation(.easeInOut(duration: 1.5)) {
            cameraPosition = .region(MKCoordinateRegion(
                coordinates: allCoordinates,
                padding: 150
            ))
        }
    }
}

/// Représente une route de train sur la carte
///
/// Cette structure contient les coordonnées géographiques qui définissent
/// le tracé d'un trajet ferroviaire sur la carte.
public struct TrainRoute: Identifiable, Equatable {
    public let id = UUID()
    let coordinates: [CLLocationCoordinate2D]
    let company: String?

    init(coordinates: [CLLocationCoordinate2D], company: String? = nil) {
        self.coordinates = coordinates
        self.company = company
    }

    var routeColor: Color {
        guard let company = company?.lowercased() else { return .blue }
        switch company {
        case "sncf": return .blue
        case "ter": return .green
        case "eurostar": return .yellow
        case "db", "deutsche bahn": return .red
        case "ouigo": return .pink
        case "thalys": return .purple
        default: return .blue
        }
    }

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
