//
//  MapView.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 28/02/2025.
//

import SwiftUI
import MapKit
import Combine

/// Vue qui affiche une carte avec les trajets ferroviaires
///
/// Cette vue utilise MapKit pour afficher une carte interactive avec
/// les trajets ferroviaires sous forme de lignes et de points.
///
/// ## Fonctionnalités
/// - Affichage des trajets sous forme de polylignes
/// - Marquage des points de départ et d'arrivée
/// - Ajustement de l'espace pour le bottom sheet
struct MapView: View {
    @Binding var sheetSize: PresentationDetent
    @ObservedObject var mapSettings: MapSettings
    @State private var bottomSheetHeight: CGFloat = UIScreen.main.bounds.height * 0.3
    @State private var topSafeAreaHeight: CGFloat = 0
    
    var body: some View {
        Map(position: $mapSettings.cameraPosition) {
            mapContent
        }
        .mapStyle(.standard)
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .safeAreaInset(edge: .top) {
            Color.clear
                .frame(height: topSafeAreaHeight)
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear
                .frame(height: bottomSheetHeight)
        }
        .onAppear {
            LogManager.info("MapView apparaît", category: "viewcycle")
            updateBottomSheetHeight()
            
            if mapSettings.selectedRoute == nil {
                mapSettings.updateCameraToShowAllRoutes()
            }
            
            let window = UIApplication.shared.windows.first
               topSafeAreaHeight = window?.safeAreaInsets.top ?? 0
               LogManager.debug("Safe area supérieure: \(topSafeAreaHeight)", category: "ui_state")
        }
        .onChange(of: sheetSize) { _, newSize in
            LogManager.debug("Changement de taille du bottom sheet: \(newSize)", category: "ui_state")
            updateBottomSheetHeight()
        }
        .onChange(of: mapSettings.trainRoutes) { _, newRoutes in
            LogManager.debug("Mise à jour des routes sur la carte: \(newRoutes.count) routes", category: "map")
        }
    }
    
    // Extrait le contenu de la carte dans une propriété calculée
    private var mapContent: some MapContent {
        ForEach(mapSettings.trainRoutes) { route in
            MapPolyline(coordinates: route.coordinates)
                .stroke(.blue, lineWidth: 3)
                .mapOverlayLevel(level: mapSettings.selectedRoute?.id == route.id ? .aboveRoads : .aboveLabels)
            
            if let firstCoord = route.coordinates.first {
                Annotation("", coordinate: firstCoord) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 7))
                        .foregroundStyle(.blue)
                }
            }
            
            ForEach(1..<max(1, route.coordinates.count-1), id: \.self) { index in
                Annotation("", coordinate: route.coordinates[index]) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 5))
                        .foregroundStyle(.blue.opacity(0.7))
                }
            }
            
            // Point d'arrivée (dernier index)
            if let lastCoord = route.coordinates.last, route.coordinates.count > 1 {
                Annotation("", coordinate: lastCoord) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 7))
                        .foregroundStyle(.blue)
                }
            }
        }
    }
    
    /// Met à jour la hauteur du bottom sheet en fonction de sa taille
    private func updateBottomSheetHeight() {
        let screenHeight = UIScreen.main.bounds.height
        
        switch sheetSize {
        case .medium:
            bottomSheetHeight = screenHeight * 0.5
            LogManager.debug("Hauteur du bottom sheet ajustée à \(bottomSheetHeight) (medium)", category: "ui_state")
        case .large:
            bottomSheetHeight = screenHeight * 0.8
            LogManager.debug("Hauteur du bottom sheet ajustée à \(bottomSheetHeight) (large)", category: "ui_state")
        default:
            bottomSheetHeight = screenHeight * 0.3
            LogManager.debug("Hauteur du bottom sheet ajustée à \(bottomSheetHeight) (valeur par défaut)", category: "ui_state")
        }
    }
}
