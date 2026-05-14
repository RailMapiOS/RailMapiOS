//
//  MapView.swift
//  RailMapiOS
//
//  Thin SwiftUI wrapper over MapKitView (UIViewRepresentable / MKMapView).
//  Native UIKit avoids the SwiftUI Map + safeAreaInset white-flash bug.
//

import ComposableArchitecture
import MapKit
import SwiftUI

struct MapView: View {
    let store: StoreOf<MapFeature>

    /// Map's bottom inset is fixed to the smallest sheet detent (`.fraction(0.3)`).
    /// The map does not adapt when the sheet expands — controls and watermark stay
    /// at this position, the sheet just covers more of the map. This is simpler,
    /// avoids re-layout flashes, and matches the "map under sheet" pattern.
    private static let fixedSheetFraction: CGFloat = 0.3

    /// When fitting the camera to a journey, we use a slightly larger bottom
    /// inset than the resting sheet (`0.3`) so the framing keeps a small buffer
    /// above the sheet handle, but not so much that the routes look tiny.
    private static let cameraSheetFraction: CGFloat = 0.3

    /// Past routes are hidden from the default map view, except the one currently selected
    /// (so tapping a past journey in "Trajets passés" still highlights it on the map).
    private var visibleRoutes: [TrainRoute] {
        let selectedID = store.selectedRoute?.id
        return store.trainRoutes.filter { !$0.isPast || $0.id == selectedID }
    }

    var body: some View {
        GeometryReader { proxy in
            MapKitView(
                routes: visibleRoutes,
                selectedRoute: store.selectedRoute,
                vehicleMarkers: store.vehicleMarkers,
                bottomInset: proxy.size.height * Self.fixedSheetFraction,
                cameraBottomInset: proxy.size.height * Self.cameraSheetFraction,
                cameraTrigger: store.cameraUpdateTrigger
            )
            .ignoresSafeArea()
        }
    }
}
