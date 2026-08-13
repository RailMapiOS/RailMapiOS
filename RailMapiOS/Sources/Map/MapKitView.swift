//
//  MapKitView.swift
//  RailMapiOS
//
//  UIViewRepresentable wrapping MKMapView for native UIKit performance.
//  Avoids the white-flash artifacts of SwiftUI Map + animated safeAreaInset.
//

import MapKit
import SwiftUI

struct MapKitView: UIViewRepresentable {
    let routes: [TrainRoute]
    let selectedRoute: TrainRoute?
    /// Live train markers (GTFS-RT vehicle positions).
    let vehicleMarkers: [VehicleMarker]
    /// Bottom layout margin: pushes compass, scale, and Apple Maps watermark above the sheet.
    let bottomInset: CGFloat
    /// Bottom inset used **only** when fitting the camera to journeys/routes —
    /// pretends the sheet is at medium so the framing stays visible when the
    /// user expands the sheet beyond the smallest detent.
    let cameraBottomInset: CGFloat
    /// Recompute camera region (set of all routes' coords or selected route).
    let cameraTrigger: Int

    // MARK: - UIViewRepresentable

    func makeUIView(context: UIViewRepresentableContext<MapKitView>) -> MKMapView {
        let mapView = LayoutReportingMapView()
        mapView.delegate = context.coordinator
        // The first `updateUIView` runs before the map has been laid out, so a
        // camera fit requested there lands on a zero-sized view and is silently
        // dropped. Replaying it on the first real layout is what keeps the map
        // framed on the journeys instead of stuck at MapKit's default region.
        mapView.onLayout = { [weak mapView, weak coordinator = context.coordinator] in
            guard let mapView, let coordinator else { return }
            coordinator.flushPendingCamera(on: mapView)
        }
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.showsUserLocation = false
        mapView.preferredConfiguration = MKStandardMapConfiguration(elevationStyle: .flat)
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: UIViewRepresentableContext<MapKitView>) {
        // Update insets so controls + watermark stay above the sheet
        mapView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: bottomInset, right: 0)

        // Sync overlays + annotations. Polylines need vehicle positions to split into
        // past (grey) and remaining (colored) portions.
        context.coordinator.sync(routes: routes, selected: selectedRoute, vehicles: vehicleMarkers, on: mapView)
        context.coordinator.syncVehicles(markers: vehicleMarkers, on: mapView)

        // Update camera if trigger changed
        if context.coordinator.lastCameraTrigger != cameraTrigger {
            context.coordinator.lastCameraTrigger = cameraTrigger
            requestCamera(on: mapView, coordinator: context.coordinator)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    // MARK: - Camera

    private func requestCamera(on mapView: MKMapView, coordinator: Coordinator) {
        let candidates: [CLLocationCoordinate2D]
        if let selected = selectedRoute, !selected.stopCoordinates.isEmpty {
            candidates = selected.stopCoordinates
        } else {
            candidates = routes.flatMap(\.stopCoordinates)
        }
        // Drop anything MapKit would refuse: one bad coordinate stretches the
        // bounding box across the planet and the framing is lost.
        let coords = candidates.filter { CLLocationCoordinate2DIsValid($0) }
        guard !coords.isEmpty else { return }

        // Build a tight bounding rect from the coords and let MapKit fit it
        // inside the unobstructed area (above the sheet at medium detent).
        let rect = coords
            .map { MKMapPoint($0) }
            .reduce(MKMapRect.null) { acc, point in
                let pointRect = MKMapRect(origin: point, size: MKMapSize(width: 0, height: 0))
                return acc.isNull ? pointRect : acc.union(pointRect)
            }
        guard !rect.isNull else { return }

        // A single stop — or several that resolved to the same point — makes a
        // zero-sized rect. `setVisibleMapRect` cannot fit that and lands on an
        // arbitrary zoom, so give it a real neighbourhood to frame instead.
        let fitted = rect.isEmpty ? Self.neighbourhood(around: rect.origin) : rect

        let horizontalPadding: CGFloat = selectedRoute == nil ? 24 : 32
        let topPadding: CGFloat = 48
        let edgePadding = UIEdgeInsets(
            top: topPadding,
            left: horizontalPadding,
            bottom: cameraBottomInset,
            right: horizontalPadding
        )

        coordinator.setCamera(rect: fitted, edgePadding: edgePadding, on: mapView)
    }

    /// A ~2 km square centred on `point`, used when the bounding box collapses
    /// to a single location.
    private static func neighbourhood(around point: MKMapPoint) -> MKMapRect {
        let side = 2_000 * MKMapPointsPerMeterAtLatitude(point.coordinate.latitude)
        return MKMapRect(
            x: point.x - side / 2,
            y: point.y - side / 2,
            width: side,
            height: side
        )
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, MKMapViewDelegate {
        var lastCameraTrigger: Int = -1

        // MARK: Camera

        /// A fit requested while the map still had no size. Replayed by
        /// `flushPendingCamera(on:)` on the first layout that gives it one.
        private var pendingCamera: (rect: MKMapRect, edgePadding: UIEdgeInsets)?

        func setCamera(rect: MKMapRect, edgePadding: UIEdgeInsets, on mapView: MKMapView) {
            guard canFit(edgePadding, in: mapView) else {
                pendingCamera = (rect, edgePadding)
                return
            }
            pendingCamera = nil
            mapView.setVisibleMapRect(rect, edgePadding: edgePadding, animated: true)
        }

        func flushPendingCamera(on mapView: MKMapView) {
            guard let pending = pendingCamera, canFit(pending.edgePadding, in: mapView) else { return }
            pendingCamera = nil
            // Not animated: this is the initial framing, not a change the user
            // is watching happen.
            mapView.setVisibleMapRect(pending.rect, edgePadding: pending.edgePadding, animated: false)
        }

        /// The map must be laid out *and* leave room once the paddings are
        /// subtracted, otherwise `setVisibleMapRect` produces an arbitrary zoom.
        private func canFit(_ edgePadding: UIEdgeInsets, in mapView: MKMapView) -> Bool {
            let size = mapView.bounds.size
            return size.width - edgePadding.left - edgePadding.right > 0
                && size.height - edgePadding.top - edgePadding.bottom > 0
        }

        /// Selection state, used by the renderer.
        private var selectedRouteID: UUID?
        /// Live vehicle annotations, indexed by journey ID — updated in place.
        private var vehicleAnnotations: [UUID: VehicleAnnotation] = [:]

        // MARK: Route overlays
        //
        // Two `MKPolyline`s per route — travelled (grey) and remaining (operator
        // colour) — rendered by `MKPolylineRenderer`, which re-strokes as vectors
        // at every zoom level. An `MKGradientPolylineRenderer` painting a single
        // persistent line was tried here to avoid rebuilding on each tick: it
        // does not re-rasterise on zoom, so the track turned into thick pixelated
        // strokes as soon as the user zoomed in. Crispness wins.
        //
        // Instead the rebuild is *gated*: it only happens when the shape changes,
        // when the selection changes, or when the cut has travelled far enough on
        // screen to be visible. That keeps the previous per-tick teardown — which
        // is what made the marker stutter — without touching how it is drawn.

        /// Per-polyline render metadata — which route it belongs to, and whether
        /// it represents the already-travelled portion (rendered in grey).
        struct PolylineMeta {
            let route: TrainRoute
            let isPast: Bool
        }
        private var polylineRoutes: [ObjectIdentifier: PolylineMeta] = [:]
        /// The overlays currently on the map for each route.
        private var routeOverlays: [UUID: [MKPolyline]] = [:]
        /// What each route's overlays were built for. Rebuilt when this changes.
        private var routeBuildKeys: [UUID: RouteBuildKey] = [:]
        /// Where the travelled/remaining cut sat when the overlays were last
        /// built, so movement can be measured in screen points.
        private var routeCutCoordinates: [UUID: CLLocationCoordinate2D] = [:]
        /// Route ids + selection the stop annotations were last built for.
        private var stopAnnotationKey: [UUID: Bool] = [:]

        /// Everything except the cut position: a change here always forces a
        /// rebuild, whereas the cut is compared in screen space.
        struct RouteBuildKey: Equatable {
            let geometry: Int
            let isSelected: Bool
            let hasSelection: Bool
            let hasMarker: Bool
        }

        /// Below this on-screen movement of the cut, rebuilding would redraw the
        /// same picture. Being screen-space, it self-adjusts with zoom: rare
        /// rebuilds with the whole route framed, finer ones when zoomed in.
        private static let cutRebuildThreshold: CGFloat = 1.5

        // MARK: Sync overlays + annotations

        func sync(routes: [TrainRoute], selected: TrainRoute?, vehicles: [VehicleMarker], on mapView: MKMapView) {
            selectedRouteID = selected?.id
            let drawable = routes.filter { $0.routeCoordinates.count >= 2 }

            // Index vehicle markers by route so we know where to cut each line.
            let markerByRoute: [UUID: VehicleMarker] = Dictionary(
                vehicles.compactMap { m -> (UUID, VehicleMarker)? in
                    guard let rid = m.routeID else { return nil }
                    return (rid, m)
                },
                uniquingKeysWith: { first, _ in first }
            )

            syncRouteOverlays(drawable, markerByRoute: markerByRoute, on: mapView)
            syncStopAnnotations(drawable, selected: selected, on: mapView)
        }

        private func syncRouteOverlays(
            _ routes: [TrainRoute],
            markerByRoute: [UUID: VehicleMarker],
            on mapView: MKMapView
        ) {
            let wanted = Set(routes.map(\.id))
            for (id, overlays) in routeOverlays where !wanted.contains(id) {
                remove(overlays, for: id, from: mapView)
            }

            for route in routes {
                let snap = markerByRoute[route.id].flatMap {
                    BearingMath.snap(point: $0.coordinate, to: route.routeCoordinates)
                }

                var hasher = Hasher()
                hasher.combine(route.routeCoordinates.count)
                hasher.combine(route.routeCoordinates.last?.latitude ?? 0)
                hasher.combine(route.routeCoordinates.last?.longitude ?? 0)
                let key = RouteBuildKey(
                    geometry: hasher.finalize(),
                    isSelected: route.id == selectedRouteID,
                    hasSelection: selectedRouteID != nil,
                    hasMarker: snap != nil
                )

                if routeBuildKeys[route.id] == key, !cutMovedVisibly(snap, for: route.id, on: mapView) {
                    continue
                }

                remove(routeOverlays[route.id] ?? [], for: route.id, from: mapView)
                routeBuildKeys[route.id] = key
                routeCutCoordinates[route.id] = snap?.point

                var built: [MKPolyline] = []
                if let snap {
                    let coords = route.routeCoordinates
                    let travelled = Array(coords[0...snap.segmentIndex]) + [snap.point]
                    let remaining = [snap.point] + Array(coords[(snap.segmentIndex + 1)...])
                    if travelled.count >= 2 {
                        built.append(add(travelled, of: route, isPast: true, to: mapView))
                    }
                    if remaining.count >= 2 {
                        built.append(add(remaining, of: route, isPast: false, to: mapView))
                    }
                } else {
                    built.append(add(route.routeCoordinates, of: route, isPast: false, to: mapView))
                }
                routeOverlays[route.id] = built
            }
        }

        /// True when the cut has moved at least `cutRebuildThreshold` points on
        /// screen since the overlays were built.
        private func cutMovedVisibly(
            _ snap: BearingMath.SnapResult?,
            for routeID: UUID,
            on mapView: MKMapView
        ) -> Bool {
            guard let new = snap?.point else { return false }
            guard let old = routeCutCoordinates[routeID] else { return true }
            let a = mapView.convert(old, toPointTo: mapView)
            let b = mapView.convert(new, toPointTo: mapView)
            return hypot(a.x - b.x, a.y - b.y) >= Self.cutRebuildThreshold
        }

        private func add(
            _ coordinates: [CLLocationCoordinate2D],
            of route: TrainRoute,
            isPast: Bool,
            to mapView: MKMapView
        ) -> MKPolyline {
            let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
            polylineRoutes[ObjectIdentifier(polyline)] = PolylineMeta(route: route, isPast: isPast)
            mapView.addOverlay(polyline, level: .aboveRoads)
            return polyline
        }

        private func remove(_ overlays: [MKPolyline], for routeID: UUID, from mapView: MKMapView) {
            for overlay in overlays {
                mapView.removeOverlay(overlay)
                polylineRoutes[ObjectIdentifier(overlay)] = nil
            }
            routeOverlays[routeID] = nil
            routeBuildKeys[routeID] = nil
            routeCutCoordinates[routeID] = nil
        }

        /// Stop dots depend only on the routes and the selection, so they are
        /// rebuilt when one of those changes — not on every position tick.
        private func syncStopAnnotations(_ routes: [TrainRoute], selected: TrainRoute?, on mapView: MKMapView) {
            let key = Dictionary(routes.map { ($0.id, $0.id == selected?.id) }, uniquingKeysWith: { first, _ in first })
            guard key != stopAnnotationKey else { return }
            stopAnnotationKey = key

            mapView.removeAnnotations(mapView.annotations.filter { $0 is StopAnnotation })

            for route in routes {
                let isSelected = (selected?.id == route.id)
                if let firstCoord = route.stopCoordinates.first {
                    mapView.addAnnotation(StopAnnotation(coordinate: firstCoord, route: route, kind: isSelected ? .endpointSelected : .endpoint))
                }
                if let lastCoord = route.stopCoordinates.last, route.stopCoordinates.count > 1 {
                    mapView.addAnnotation(StopAnnotation(coordinate: lastCoord, route: route, kind: isSelected ? .endpointSelected : .endpoint))
                }
                for coord in route.stopCoordinates.dropFirst().dropLast() {
                    mapView.addAnnotation(StopAnnotation(coordinate: coord, route: route, kind: .intermediate))
                }
            }
        }

        // MARK: Vehicle markers (live train icons)

        func syncVehicles(markers: [VehicleMarker], on mapView: MKMapView) {
            let incomingIDs = Set(markers.map(\.id))
            let staleIDs = vehicleAnnotations.keys.filter { !incomingIDs.contains($0) }
            for id in staleIDs {
                if let annotation = vehicleAnnotations.removeValue(forKey: id) {
                    mapView.removeAnnotation(annotation)
                }
            }
            for marker in markers {
                // MapKit silently ignores an annotation with an invalid
                // coordinate — it never registers as its KVO observer, and the
                // matching `removeAnnotation` later throws "not registered as
                // an observer". Never hand it one.
                guard CLLocationCoordinate2DIsValid(marker.coordinate) else { continue }
                if let existing = vehicleAnnotations[marker.id] {
                    existing.update(coordinate: marker.coordinate)
                } else {
                    let annotation = VehicleAnnotation(marker: marker)
                    vehicleAnnotations[marker.id] = annotation
                    mapView.addAnnotation(annotation)
                }
            }
        }

        // MARK: MKMapViewDelegate

        func mapView(_ mapView: MKMapView, rendererFor overlay: any MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? MKPolyline,
                  let meta = polylineRoutes[ObjectIdentifier(polyline)] else {
                return MKOverlayRenderer(overlay: overlay)
            }
            let renderer = MKPolylineRenderer(polyline: polyline)
            let isSelected = (meta.route.id == selectedRouteID)
            let dimmed = selectedRouteID != nil && !isSelected

            let baseColor: UIColor = meta.isPast
                ? UIColor.systemGray3
                : UIColor(meta.route.routeColor)
            let opacity: CGFloat = dimmed ? 0.3 : (meta.isPast ? 0.7 : 1.0)
            renderer.strokeColor = baseColor.withAlphaComponent(opacity)
            renderer.lineWidth = isSelected ? 5 : 3
            return renderer
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
            // Live train: the system location puck, same as the GPS position dot
            // in Maps. It has no orientation, so nothing has to be re-rendered
            // when the train turns or the map rotates.
            if let vehicle = annotation as? VehicleAnnotation {
                let id = "vehicle"
                let view = (mapView.dequeueReusableAnnotationView(withIdentifier: id) as? LocationPuckAnnotationView)
                    ?? LocationPuckAnnotationView(annotation: vehicle, reuseIdentifier: id)
                view.annotation = vehicle
                view.canShowCallout = false
                view.displayPriority = .required
                view.zPriority = MKAnnotationViewZPriority(rawValue: 1000)
                return view
            }

            // Stop dots
            guard let stop = annotation as? StopAnnotation else { return nil }
            let id = "stop"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: id)
                ?? MKAnnotationView(annotation: stop, reuseIdentifier: id)
            view.annotation = stop
            view.canShowCallout = false

            let size: CGFloat
            let opacity: CGFloat
            let color: UIColor

            switch stop.kind {
            case .endpoint:
                size = 7
                opacity = (selectedRouteID != nil && stop.route.id != selectedRouteID) ? 0.3 : 1.0
                color = UIColor(stop.route.routeColor)
            case .endpointSelected:
                size = 10
                opacity = 1.0
                color = UIColor(stop.route.routeColor)
            case .intermediate:
                size = 5
                opacity = (selectedRouteID != nil && stop.route.id != selectedRouteID) ? 0.3 : 0.7
                color = UIColor(stop.route.routeColor)
            }

            view.frame = CGRect(x: 0, y: 0, width: size, height: size)
            view.layer.cornerRadius = size / 2
            view.layer.masksToBounds = true
            view.backgroundColor = color.withAlphaComponent(opacity)
            return view
        }

    }
}

// MARK: - Location puck (live train)

/// The GPS-position look from Maps: a blue disc with a white ring and a soft
/// shadow. Replaces a `MKMarkerAnnotationView` balloon whose train glyph was
/// re-rendered, rotated to the bearing, on every position tick and every map
/// heading change. Being orientation-free, it needs no redraw at all — the
/// annotation's coordinate change is the only thing that moves it.
private final class LocationPuckAnnotationView: MKAnnotationView {
    private static let diameter: CGFloat = 22

    override init(annotation: (any MKAnnotation)?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        let size = Self.diameter
        frame = CGRect(x: 0, y: 0, width: size, height: size)
        // Centred on the coordinate rather than pinned by its tip.
        centerOffset = .zero
        backgroundColor = .systemBlue
        layer.cornerRadius = size / 2
        layer.borderWidth = 3
        layer.borderColor = UIColor.white.cgColor
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.25
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowRadius = 3
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Map view reporting its layout

/// `MKMapView` that tells the coordinator when it gets laid out, so a camera
/// fit requested before the view had a size can be applied instead of lost.
private final class LayoutReportingMapView: MKMapView {
    var onLayout: (() -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        onLayout?()
    }
}

// MARK: - Stop annotation

private final class StopAnnotation: NSObject, MKAnnotation {
    enum Kind { case endpoint, endpointSelected, intermediate }
    let coordinate: CLLocationCoordinate2D
    let route: TrainRoute
    let kind: Kind

    init(coordinate: CLLocationCoordinate2D, route: TrainRoute, kind: Kind) {
        self.coordinate = coordinate
        self.route = route
        self.kind = kind
    }
}

// MARK: - Vehicle annotation (live train)

final class VehicleAnnotation: NSObject, MKAnnotation {
    let id: UUID
    @objc dynamic var coordinate: CLLocationCoordinate2D

    init(marker: VehicleMarker) {
        self.id = marker.id
        self.coordinate = marker.coordinate
    }

    /// Updates the position in place. The KVO change triggers MapKit's implicit
    /// Core Animation on the annotation view's position; we wrap it in a
    /// CATransaction with linear timing matching the tick interval so the
    /// marker glides continuously between updates instead of snapping.
    ///
    /// `coordinate` is `@objc dynamic`, so assigning to it already emits the
    /// KVO will/did pair MapKit listens for. The explicit
    /// `willChangeValue`/`didChangeValue` that used to wrap this assignment
    /// nested a second pair inside the automatic one, which is a documented way
    /// to desynchronise an observer's bookkeeping — `MKAnnotationManager` then
    /// tried to deregister itself from an annotation it no longer considered
    /// observed and threw "not registered as an observer".
    func update(coordinate: CLLocationCoordinate2D) {
        guard CLLocationCoordinate2DIsValid(coordinate) else { return }
        CATransaction.begin()
        CATransaction.setAnimationDuration(VehicleAnnotation.animationDuration)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .linear))
        self.coordinate = coordinate
        CATransaction.commit()
    }

    /// Matches `AppFeature.markersTickInterval` so each animation finishes right
    /// as the next position arrives — no gaps, no overshoot. Changing one
    /// without the other either stalls the marker or makes it jump.
    static let animationDuration: CFTimeInterval = 0.2
}
