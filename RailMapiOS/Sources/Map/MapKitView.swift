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
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
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
            applyCamera(to: mapView)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    // MARK: - Camera

    private func applyCamera(to mapView: MKMapView) {
        let coords: [CLLocationCoordinate2D]
        if let selected = selectedRoute, !selected.stopCoordinates.isEmpty {
            coords = selected.stopCoordinates
        } else {
            coords = routes.flatMap(\.stopCoordinates)
        }
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

        let horizontalPadding: CGFloat = selectedRoute == nil ? 24 : 32
        let topPadding: CGFloat = 48
        let edgePadding = UIEdgeInsets(
            top: topPadding,
            left: horizontalPadding,
            bottom: cameraBottomInset,
            right: horizontalPadding
        )

        mapView.setVisibleMapRect(rect, edgePadding: edgePadding, animated: true)
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, MKMapViewDelegate {
        var lastCameraTrigger: Int = -1

        /// Per-polyline render metadata — which route it belongs to, and whether it
        /// represents the already-travelled portion (rendered in grey).
        struct PolylineMeta {
            let route: TrainRoute
            let isPast: Bool
        }
        private var polylineRoutes: [ObjectIdentifier: PolylineMeta] = [:]
        /// Selection state, used by the renderer.
        private var selectedRouteID: UUID?
        /// Live vehicle annotations, indexed by journey ID — updated in place.
        private var vehicleAnnotations: [UUID: VehicleAnnotation] = [:]

        // MARK: Sync overlays + annotations

        func sync(routes: [TrainRoute], selected: TrainRoute?, vehicles: [VehicleMarker], on mapView: MKMapView) {
            selectedRouteID = selected?.id

            // Replace polylines + stop annotations only — DO NOT touch vehicle annotations
            // (they are managed separately by syncVehicles to keep their identity across ticks).
            mapView.removeOverlays(mapView.overlays)
            let stopAnnotations = mapView.annotations.filter { $0 is StopAnnotation }
            mapView.removeAnnotations(stopAnnotations)
            polylineRoutes.removeAll()

            // Index vehicle markers by route so we can split their polylines.
            let markerByRoute: [UUID: VehicleMarker] = Dictionary(
                vehicles.compactMap { m -> (UUID, VehicleMarker)? in
                    guard let rid = m.routeID else { return nil }
                    return (rid, m)
                },
                uniquingKeysWith: { first, _ in first }
            )

            for route in routes {
                guard route.routeCoordinates.count >= 2 else { continue }

                // If a vehicle is on this route, split the polyline at its snapped
                // position: past = grey, remaining = colored. Otherwise render whole.
                if let marker = markerByRoute[route.id],
                   let snap = BearingMath.snap(point: marker.coordinate, to: route.routeCoordinates) {
                    let coords = route.routeCoordinates
                    let pastCoords = Array(coords[0...snap.segmentIndex]) + [snap.point]
                    let futureCoords = [snap.point] + Array(coords[(snap.segmentIndex + 1)...])

                    if pastCoords.count >= 2 {
                        let pastLine = MKPolyline(coordinates: pastCoords, count: pastCoords.count)
                        polylineRoutes[ObjectIdentifier(pastLine)] = PolylineMeta(route: route, isPast: true)
                        mapView.addOverlay(pastLine, level: .aboveRoads)
                    }
                    if futureCoords.count >= 2 {
                        let futureLine = MKPolyline(coordinates: futureCoords, count: futureCoords.count)
                        polylineRoutes[ObjectIdentifier(futureLine)] = PolylineMeta(route: route, isPast: false)
                        mapView.addOverlay(futureLine, level: .aboveRoads)
                    }
                } else {
                    let polyline = MKPolyline(coordinates: route.routeCoordinates, count: route.routeCoordinates.count)
                    polylineRoutes[ObjectIdentifier(polyline)] = PolylineMeta(route: route, isPast: false)
                    mapView.addOverlay(polyline)
                }
                // Stop annotations
                let isSelected = (selected?.id == route.id)
                if let firstCoord = route.stopCoordinates.first {
                    mapView.addAnnotation(StopAnnotation(coordinate: firstCoord, route: route, kind: isSelected ? .endpointSelected : .endpoint))
                }
                if let lastCoord = route.stopCoordinates.last, route.stopCoordinates.count > 1 {
                    mapView.addAnnotation(StopAnnotation(coordinate: lastCoord, route: route, kind: isSelected ? .endpointSelected : .endpoint))
                }
                // Intermediate stops
                let intermediates = route.stopCoordinates.dropFirst().dropLast()
                for coord in intermediates {
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
                if let existing = vehicleAnnotations[marker.id] {
                    existing.update(coordinate: marker.coordinate, bearing: marker.bearing)
                    if let view = mapView.view(for: existing) as? MKMarkerAnnotationView {
                        Self.applyGlyphRotation(to: view, bearing: marker.bearing, mapHeading: mapView.camera.heading)
                    }
                } else {
                    let annotation = VehicleAnnotation(marker: marker)
                    vehicleAnnotations[marker.id] = annotation
                    mapView.addAnnotation(annotation)
                }
            }
        }

        /// Re-applies glyph rotation to every visible vehicle pin when the map's heading
        /// changes — keeps the train glyph pointing in geographic direction while the
        /// pin shape itself stays upright.
        func refreshVehicleRotations(on mapView: MKMapView) {
            for (_, annotation) in vehicleAnnotations {
                if let view = mapView.view(for: annotation) as? MKMarkerAnnotationView {
                    Self.applyGlyphRotation(to: view, bearing: annotation.bearing, mapHeading: mapView.camera.heading)
                }
            }
        }

        /// Rotates only the glyph inside the native pin. Bearing is a compass azimuth
        /// (0 = N, clockwise). We subtract `mapHeading` so the glyph stays tied to the
        /// world, not the screen.
        static func applyGlyphRotation(to view: MKMarkerAnnotationView, bearing: Double, mapHeading: Double) {
            let radians = CGFloat((bearing - mapHeading) * .pi / 180)
            view.glyphImage = trainGlyph(rotation: radians)
        }

        // MARK: MKMapViewDelegate

        func mapView(_ mapView: MKMapView, rendererFor overlay: any MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? MKPolyline,
                  let meta = polylineRoutes[ObjectIdentifier(polyline)] else {
                return MKOverlayRenderer(overlay: overlay)
            }
            let renderer = MKPolylineRenderer(polyline: polyline)
            let isSelected = (meta.route.id == selectedRouteID)
            let hasSelection = selectedRouteID != nil
            let dimmed = hasSelection && !isSelected

            let baseColor: UIColor = meta.isPast
                ? UIColor.systemGray3
                : UIColor(meta.route.routeColor)
            let opacity: CGFloat = dimmed ? 0.3 : (meta.isPast ? 0.7 : 1.0)
            renderer.strokeColor = baseColor.withAlphaComponent(opacity)
            renderer.lineWidth = isSelected ? 5 : 3
            return renderer
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
            // Vehicle marker: native pin (MKMarkerAnnotationView) with a rotating glyph.
            // The pin shape stays upright; only the inner train icon turns to indicate heading.
            if let vehicle = annotation as? VehicleAnnotation {
                let id = "vehicle"
                let view = (mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView)
                    ?? MKMarkerAnnotationView(annotation: vehicle, reuseIdentifier: id)
                view.annotation = vehicle
                view.canShowCallout = false
                view.markerTintColor = .systemBlue
                view.displayPriority = .required
                view.zPriority = MKAnnotationViewZPriority(rawValue: 1000)
                Self.applyGlyphRotation(to: view, bearing: vehicle.bearing, mapHeading: mapView.camera.heading)
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

        // MARK: Map heading → marker rotation

        /// Last camera heading we reacted to. Used to skip no-op redraws.
        private var lastHeading: CLLocationDirection = -1

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            let heading = mapView.camera.heading
            guard abs(heading - lastHeading) > 0.5 else { return }
            lastHeading = heading
            refreshVehicleRotations(on: mapView)
        }

        // MARK: - Train glyph (rotates inside the native pin)

        /// Cache of rotated glyphs keyed by 5° buckets — keeps re-rendering cheap on
        /// each frame even with many vehicles.
        private static var glyphCache: [Int: UIImage] = [:]

        /// Returns a train glyph rotated by `rotation` radians, sized to fit
        /// `MKMarkerAnnotationView.glyphImage`. The base symbol's "front" faces right,
        /// so we apply an extra -π/2 to align angle-0 with North (up).
        static func trainGlyph(rotation: CGFloat) -> UIImage {
            let bucket = Int((rotation * 180 / .pi).rounded() / 5) * 5
            if let cached = glyphCache[bucket] { return cached }

            let size: CGFloat = 28
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
            let image = renderer.image { ctx in
                let cg = ctx.cgContext
                let cfg = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
                guard let glyph = UIImage(systemName: "train.side.front.car", withConfiguration: cfg)?
                    .withTintColor(.white, renderingMode: .alwaysOriginal)
                else { return }
                cg.translateBy(x: size / 2, y: size / 2)
                cg.rotate(by: rotation - .pi / 2)
                let r = CGRect(
                    x: -glyph.size.width / 2,
                    y: -glyph.size.height / 2,
                    width: glyph.size.width,
                    height: glyph.size.height
                )
                glyph.draw(in: r)
            }
            glyphCache[bucket] = image
            return image
        }
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
    var bearing: Double

    init(marker: VehicleMarker) {
        self.id = marker.id
        self.coordinate = marker.coordinate
        self.bearing = marker.bearing
    }

    /// Updates position + heading in place. The KVO change triggers MapKit's
    /// implicit Core Animation on the annotation view's position; we wrap it in
    /// a CATransaction with linear timing matching the tick interval so the
    /// marker glides continuously between updates instead of snapping.
    func update(coordinate: CLLocationCoordinate2D, bearing: Double) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(VehicleAnnotation.animationDuration)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .linear))
        self.willChangeValue(forKey: "coordinate")
        self.coordinate = coordinate
        self.didChangeValue(forKey: "coordinate")
        self.bearing = bearing
        CATransaction.commit()
    }

    /// Matches `AppFeature.markersTickInterval` so each animation finishes right
    /// as the next position arrives — no gaps, no overshoot.
    static let animationDuration: CFTimeInterval = 1.0
}
