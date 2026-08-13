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
    /// The journeys sheet's frame in global coordinates, reported by `AppView`.
    /// `.zero` until it has been measured, or when no sheet is shown (iPad).
    var sheetFrame: CGRect = .zero

    /// Fallback share of the map the sheet is assumed to cover before its frame
    /// has been measured — the smallest detent, matching the previous behaviour.
    /// Only used for the first frame or two.
    private static let assumedBottomFraction: CGFloat = 0.3

    /// Past routes are hidden from the default map view, except the one currently selected
    /// (so tapping a past journey in "Trajets passés" still highlights it on the map).
    private var visibleRoutes: [TrainRoute] {
        let selectedID = store.selectedRoute?.id
        return store.trainRoutes.filter { !$0.isPast || $0.id == selectedID }
    }

    var body: some View {
        GeometryReader { proxy in
            let insets = obscuredInsets(mapFrame: proxy.frame(in: .global), size: proxy.size)
            MapKitView(
                routes: visibleRoutes,
                selectedRoute: store.selectedRoute,
                vehicleMarkers: store.vehicleMarkers,
                obscured: insets,
                cameraTrigger: store.cameraUpdateTrigger
            )
            .ignoresSafeArea()
        }
    }

    /// Which edge the sheet covers, measured when possible.
    ///
    /// The map does not follow the sheet as it grows past its smallest detent:
    /// re-framing on every drag was noisy, and the old code deliberately pinned
    /// the camera inset to the smallest detent for that reason. So a measured
    /// *bottom* overlap is clamped to that share, while a *side* overlap is
    /// taken as-is — a trailing sheet's width is what it is, and pretending it
    /// is narrower would push the route under it.
    private func obscuredInsets(mapFrame: CGRect, size: CGSize) -> MapObscuredInsets {
        var insets = MapObscuredInsets.resolve(mapFrame: mapFrame, sheetFrame: sheetFrame)
        if insets == .none {
            insets.bottom = size.height * Self.assumedBottomFraction
        } else if insets.bottom > 0 {
            insets.bottom = min(insets.bottom, size.height * Self.assumedBottomFraction)
        }
        return insets
    }
}
