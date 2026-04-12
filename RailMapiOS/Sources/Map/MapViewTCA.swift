//
//  MapViewTCA.swift
//  RailMapiOS
//

import ComposableArchitecture
import MapKit
import SwiftUI

struct MapViewTCA: View {
    let store: StoreOf<MapFeature>
    let sheetSize: PresentationDetent

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var bottomSheetHeight: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            Map(position: $cameraPosition) {
                mapContent
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
            .onAppear {
                updateBottomSheetHeight(screenHeight: proxy.size.height)
                updateCamera()
            }
            .onChange(of: sheetSize) { _, _ in
                updateBottomSheetHeight(screenHeight: proxy.size.height)
            }
            .onChange(of: store.cameraUpdateTrigger) { _, _ in
                updateCamera()
            }
        }
    }

    // MARK: - Map Content

    @MapContentBuilder
    private var mapContent: some MapContent {
        ForEach(store.trainRoutes) { route in
            let isSelected = store.selectedRoute?.id == route.id
            let hasSelection = store.selectedRoute != nil

            MapPolyline(coordinates: route.routeCoordinates)
                .stroke(
                    route.routeColor.opacity(hasSelection && !isSelected ? 0.3 : 1.0),
                    lineWidth: isSelected ? 5 : 3
                )
                .mapOverlayLevel(level: isSelected ? .aboveRoads : .aboveLabels)

            if let firstCoord = route.stopCoordinates.first {
                Annotation("", coordinate: firstCoord) {
                    Circle()
                        .fill(route.routeColor)
                        .frame(width: isSelected ? 10 : 7, height: isSelected ? 10 : 7)
                        .opacity(hasSelection && !isSelected ? 0.3 : 1.0)
                }
            }

            ForEach(1..<max(1, route.stopCoordinates.count - 1), id: \.self) { index in
                Annotation("", coordinate: route.stopCoordinates[index]) {
                    Circle()
                        .fill(route.routeColor.opacity(0.7))
                        .frame(width: 5, height: 5)
                        .opacity(hasSelection && !isSelected ? 0.3 : 1.0)
                }
            }

            if let lastCoord = route.stopCoordinates.last, route.stopCoordinates.count > 1 {
                Annotation("", coordinate: lastCoord) {
                    Circle()
                        .fill(route.routeColor)
                        .frame(width: isSelected ? 10 : 7, height: isSelected ? 10 : 7)
                        .opacity(hasSelection && !isSelected ? 0.3 : 1.0)
                }
            }
        }
    }

    // MARK: - Camera

    private func updateCamera() {
        withAnimation(.easeInOut(duration: 1.5)) {
            if let selected = store.selectedRoute, !selected.stopCoordinates.isEmpty {
                cameraPosition = .region(MKCoordinateRegion(coordinates: selected.stopCoordinates, padding: 250))
            } else if !store.trainRoutes.isEmpty {
                let allCoords = store.trainRoutes.flatMap(\.stopCoordinates)
                if !allCoords.isEmpty {
                    cameraPosition = .region(MKCoordinateRegion(coordinates: allCoords, padding: 150))
                }
            }
        }
    }

    private func updateBottomSheetHeight(screenHeight: CGFloat) {
        switch sheetSize {
        case .medium: bottomSheetHeight = screenHeight * 0.5
        case .large: bottomSheetHeight = screenHeight * 0.8
        default: bottomSheetHeight = screenHeight * 0.3
        }
    }
}
