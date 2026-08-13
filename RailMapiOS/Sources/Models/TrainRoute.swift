//
//  TrainRoute.swift
//  RailMapiOS
//

import CoreLocation
import MapKit
import SwiftUI

/// Représente une route de train sur la carte
public struct TrainRoute: Identifiable, Equatable {
    /// Identity of the `Journey` this route was generated from.
    ///
    /// It must NOT be a freshly minted `UUID()`: routes are regenerated from
    /// scratch on every journey update, and live markers, map selection and
    /// resolved geometries all refer to a route by this id. A per-instance
    /// UUID made those references dangle after each regeneration, and made
    /// two trips on the same train number indistinguishable.
    public let id: UUID
    /// Stop coordinates (for annotations)
    let stopCoordinates: [CLLocationCoordinate2D]
    /// Detailed rail track coordinates (resolved via OSRM/GTFS shapes, or same as stopCoordinates)
    var routeCoordinates: [CLLocationCoordinate2D]
    let company: String?
    /// Train number / headsign, used to query RailMapAPI for exact route shape
    let headsign: String?
    /// True when the underlying journey is more than 30min past its arrival.
    /// Hidden from the default map view (re-shown when selected).
    var isPast: Bool

    init(
        id: UUID,
        coordinates: [CLLocationCoordinate2D],
        company: String? = nil,
        headsign: String? = nil,
        isPast: Bool = false
    ) {
        self.id = id
        self.stopCoordinates = coordinates
        self.routeCoordinates = coordinates
        self.company = company
        self.headsign = headsign
        self.isPast = isPast
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
        lhs.id == rhs.id &&
        lhs.isPast == rhs.isPast &&
        lhs.stopCoordinates.first == rhs.stopCoordinates.first &&
        lhs.stopCoordinates.last == rhs.stopCoordinates.last &&
        // Fingerprint rather than a full compare: shapes run to ~10k points and
        // equality is evaluated on every state diff. Without it, swapping the
        // stop-to-stop line for the resolved rail shape read as "no change".
        lhs.routeCoordinates.count == rhs.routeCoordinates.count &&
        lhs.routeCoordinates.last == rhs.routeCoordinates.last
    }
}

// MARK: - CLLocationCoordinate2D Equatable

#if swift(>=6.0)
extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
#else
extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
#endif

// MARK: - MKCoordinateRegion helper

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
