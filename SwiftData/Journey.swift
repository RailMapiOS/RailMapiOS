//
//  Journey.swift
//  
//
//  Created by Jérémie Patot on 04/08/2025.
//
//

public import Foundation
public import SwiftData
import CoreLocation


@Model public class Journey {
    public var id: UUID?
    var archived: Bool? = false
    var company: String?
    var endDate: Date?
    var headsign: String?
    var idVehiculeJourney: String?
    var startDate: Date?
    @Relationship(inverse: \Stop.journey) var stops: [Stop]?

    /// Persisted route shape coordinates (GeoJSON-style: [[lon, lat], ...]).
    /// Nil means shape has not been resolved yet.
    var routeShapeData: Data?

    /// Source of the shape: "gtfs", "signal-osrm", "overpass", "stops-only", or nil.
    var routeShapeSource: String?

    /// User dismissed the refund-eligibility banner for this journey via
    /// swipe-to-delete. Persisted so we don't re-show it on each open.
    var refundBannerDismissed: Bool? = false

    /// Active = currently in transit (`startDate ≤ now ≤ endDate`). Used to
    /// rank journeys at the top of the saved list.
    public var isActive: Bool {
        guard let startDate, let endDate else { return false }
        let now = Date()
        return startDate <= now && now <= endDate
    }

    /// Best-effort extraction of the SNCF "Line" UUID from the static tripID.
    /// Format observed:
    ///     `OCESN<train>F<x>_F:TER:FR:Line::<UUID>::<stops>:...`
    /// Falls back to `nil` when the format isn't recognised — non-SNCF
    /// operators have their own conventions and may need their own parser.
    public var routeUUID: String? {
        guard let trip = idVehiculeJourney else { return nil }
        guard let range = trip.range(of: "Line::") else { return nil }
        let suffix = trip[range.upperBound...]
        guard let endRange = suffix.range(of: "::") else { return nil }
        return String(suffix[..<endRange.lowerBound])
    }

    /// All stop IDs (`stop_area:SNCF:…`) present on the journey — used to
    /// match station-scoped alerts (closures, platform changes…).
    public var allStopIDs: Set<String> {
        Set((stops ?? []).compactMap { $0.stopinfo?.id })
    }

    public init() {}

    // MARK: - Shape persistence helpers

    func setRouteShape(coordinates: [CLLocationCoordinate2D], source: String) {
        let pairs = coordinates.map { [$0.longitude, $0.latitude] }
        routeShapeData = try? JSONEncoder().encode(pairs)
        routeShapeSource = source
    }

    func getRouteShape() -> [CLLocationCoordinate2D]? {
        guard let data = routeShapeData,
              let pairs = try? JSONDecoder().decode([[Double]].self, from: data) else { return nil }
        return pairs.compactMap { pair -> CLLocationCoordinate2D? in
            guard pair.count >= 2 else { return nil }
            return CLLocationCoordinate2D(latitude: pair[1], longitude: pair[0])
        }
    }

    /// A journey is considered "past" once its arrival is more than 30 minutes ago.
    /// Used to auto-archive: removed from the active map and listed under "Trajets passés".
    public var isPast: Bool {
        guard let endDate else { return false }
        return endDate.addingTimeInterval(30 * 60) < Date()
    }

    /// Window during which the journey should poll GTFS-RT.
    /// Starts 30 minutes before scheduled departure, ends 3 minutes after scheduled arrival.
    /// Outside this window, the journey emits no real-time traffic — keeps API noise low.
    public var isActiveForTracking: Bool {
        guard let startDate, let endDate else { return false }
        let now = Date()
        let from = startDate.addingTimeInterval(-30 * 60)
        let until = endDate.addingTimeInterval(3 * 60)
        return now >= from && now <= until
    }
}
