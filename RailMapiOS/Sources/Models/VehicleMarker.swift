//
//  VehicleMarker.swift
//  RailMapiOS
//
//  Live train marker on the map: GPS position + heading.
//

import CoreLocation
import Foundation

struct VehicleMarker: Identifiable, Equatable, Sendable {
    /// Stable per-journey ID (matches the source Journey.id).
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    /// Heading in degrees (0° = North, 90° = East, etc.).
    /// Either provided by GTFS-RT or computed from the route polyline.
    let bearing: Double
    let company: String?
    /// The route this marker is travelling on — used to split the polyline
    /// into "already travelled" (grey) and "remaining" (colored) portions.
    let routeID: UUID?

    static func == (lhs: VehicleMarker, rhs: VehicleMarker) -> Bool {
        lhs.id == rhs.id &&
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude &&
        lhs.bearing == rhs.bearing &&
        lhs.company == rhs.company &&
        lhs.routeID == rhs.routeID
    }
}

// MARK: - Bearing geometry

enum BearingMath {

    /// Compass bearing (degrees, 0–359) from `a` to `b`. Forward azimuth.
    static func bearing(from a: CLLocationCoordinate2D, to b: CLLocationCoordinate2D) -> Double {
        let lat1 = a.latitude * .pi / 180
        let lat2 = b.latitude * .pi / 180
        let dLon = (b.longitude - a.longitude) * .pi / 180
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radians = atan2(y, x)
        return (radians * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
    }

    /// Approximate bearing along a polyline at the position closest to `point`.
    /// Picks the segment whose midpoint is nearest to `point` and returns its forward azimuth.
    /// Returns 0 if the polyline has fewer than 2 points.
    static func bearingAlongRoute(near point: CLLocationCoordinate2D, route: [CLLocationCoordinate2D]) -> Double {
        guard route.count >= 2 else { return 0 }
        var bestSquaredDistance = Double.infinity
        var bestSegmentIndex = 0
        for i in 0..<(route.count - 1) {
            let a = route[i]
            let b = route[i + 1]
            let mid = CLLocationCoordinate2D(
                latitude: (a.latitude + b.latitude) / 2,
                longitude: (a.longitude + b.longitude) / 2
            )
            let dx = mid.latitude - point.latitude
            let dy = mid.longitude - point.longitude
            let squared = dx * dx + dy * dy
            if squared < bestSquaredDistance {
                bestSquaredDistance = squared
                bestSegmentIndex = i
            }
        }
        return bearing(from: route[bestSegmentIndex], to: route[bestSegmentIndex + 1])
    }

    // MARK: - Snap to polyline

    struct SnapResult: Sendable, Equatable {
        let point: CLLocationCoordinate2D
        /// Bearing of the segment containing the projection.
        let bearing: Double
        /// Geographic distance (meters) between the input point and the projection.
        let distanceMeters: Double
        /// Index of the polyline segment where the projection lands.
        let segmentIndex: Int

        static func == (lhs: SnapResult, rhs: SnapResult) -> Bool {
            lhs.point.latitude == rhs.point.latitude &&
            lhs.point.longitude == rhs.point.longitude &&
            lhs.bearing == rhs.bearing &&
            lhs.distanceMeters == rhs.distanceMeters &&
            lhs.segmentIndex == rhs.segmentIndex
        }
    }

    /// Snaps `point` to the closest position on `polyline` (orthogonal projection).
    /// Returns the snapped coordinate, segment bearing, distance in meters, and segment index.
    static func snap(point: CLLocationCoordinate2D, to polyline: [CLLocationCoordinate2D]) -> SnapResult? {
        guard polyline.count >= 2 else { return nil }
        let pLoc = CLLocation(latitude: point.latitude, longitude: point.longitude)

        var best: SnapResult?
        for i in 0..<(polyline.count - 1) {
            let a = polyline[i]
            let b = polyline[i + 1]
            let proj = project(point: point, onSegmentFrom: a, to: b)
            let projLoc = CLLocation(latitude: proj.latitude, longitude: proj.longitude)
            let dist = pLoc.distance(from: projLoc)
            if best == nil || dist < best!.distanceMeters {
                best = SnapResult(
                    point: proj,
                    bearing: bearing(from: a, to: b),
                    distanceMeters: dist,
                    segmentIndex: i
                )
            }
        }
        return best
    }

    /// Orthogonal projection of `point` onto segment `[a, b]`, clamped to the segment endpoints.
    /// Uses planar (lon/lat) math — accurate enough for short segments at typical rail scale.
    private static func project(point: CLLocationCoordinate2D,
                                onSegmentFrom a: CLLocationCoordinate2D,
                                to b: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let dx = b.longitude - a.longitude
        let dy = b.latitude - a.latitude
        let lengthSquared = dx * dx + dy * dy
        guard lengthSquared > 0 else { return a }
        let t = ((point.longitude - a.longitude) * dx + (point.latitude - a.latitude) * dy) / lengthSquared
        let clamped = max(0, min(1, t))
        return CLLocationCoordinate2D(
            latitude: a.latitude + clamped * dy,
            longitude: a.longitude + clamped * dx
        )
    }
}
