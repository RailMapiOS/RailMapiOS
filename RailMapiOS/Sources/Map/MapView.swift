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
    @ObservedObject var mapSettings: MapSettings
    @State private var bottomSheetHeight: CGFloat = UIScreen.main.bounds.height * 0.3
    
    var body: some View {
        Map {
            if !$mapSettings.trainRoutes.isEmpty {
                ForEach(mapSettings.trainRoutes) { route in
                    MapPolyline(coordinates: route.coordinates)
                        .stroke(.blue, lineWidth: 3)
                    
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
                    .frame(height: bottomSheetHeight)
        }
        .onChange(of: sheetSize) { newValue in
            withAnimation {
                updateBottomSheetHeight(for: newValue)
            }
        }
    }
    
    private func updateBottomSheetHeight(for size: PresentationDetent) {
        switch size {
        case .medium:
            bottomSheetHeight = UIScreen.main.bounds.height * 0.52
        default:
            bottomSheetHeight = UIScreen.main.bounds.height * 0.3
        }
    }
}
