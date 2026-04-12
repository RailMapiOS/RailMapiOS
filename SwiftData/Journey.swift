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
}
