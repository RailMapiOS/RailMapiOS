//
//  MapService.swift
//  RailMapiOS
//
//  Pure business logic for map operations: route generation and region calculation.
//  Stateless, testable, independent of TCA.
//

import CoreLocation
import Foundation
import MapKit

struct MapService: Sendable {

    // MARK: - Route Generation

    /// Generates `TrainRoute` objects from persisted journeys, using cached shape data when available.
    func generateTrainRoutes(from journeys: [Journey]) -> [TrainRoute] {
        journeys.compactMap { journey -> TrainRoute? in
            guard let stops = journey.stops, !stops.isEmpty else { return nil }

            let sortedStops = stops.sorted { s1, s2 in
                (s1.departureTimeUTC ?? s1.arrivalTimeUTC ?? .distantPast) <
                (s2.departureTimeUTC ?? s2.arrivalTimeUTC ?? .distantPast)
            }

            guard let depIdx = sortedStops.firstIndex(where: { $0.status?.lowercased() == "departure" }),
                  let arrIdx = sortedStops.lastIndex(where: { $0.status?.lowercased() == "arrival" }),
                  depIdx <= arrIdx else { return nil }

            let coordinates = Array(sortedStops[depIdx...arrIdx]).compactMap { stop -> CLLocationCoordinate2D? in
                guard let info = stop.stopinfo, let lat = info.latitude, let lon = info.longitude else { return nil }
                return CLLocationCoordinate2D(latitude: lat, longitude: lon)
            }

            guard coordinates.count >= 2 else { return nil }

            var route = TrainRoute(coordinates: coordinates, company: journey.company, headsign: journey.headsign)
            if let cached = journey.getRouteShape(), cached.count > coordinates.count {
                route.routeCoordinates = cached
            }
            return route
        }
    }

    // MARK: - Camera regions

    /// Region encompassing all coordinates with padding.
    func region(for coordinates: [CLLocationCoordinate2D], padding: CGFloat = 150) -> MKCoordinateRegion? {
        guard !coordinates.isEmpty else { return nil }
        return MKCoordinateRegion(coordinates: coordinates, padding: padding)
    }

    /// Region encompassing all routes (uses stop coordinates).
    func regionEncompassing(routes: [TrainRoute], padding: CGFloat = 150) -> MKCoordinateRegion? {
        let allCoords = routes.flatMap(\.stopCoordinates)
        return region(for: allCoords, padding: padding)
    }

    // MARK: - Route matching

    /// Finds a route in `routes` that matches the journey's first/last stops.
    func findMatchingRoute(for journey: Journey, in routes: [TrainRoute]) -> TrainRoute? {
        guard let stops = journey.stops,
              let firstStop = stops.first(where: { $0.status?.lowercased() == "departure" }),
              let lastStop = stops.last(where: { $0.status?.lowercased() == "arrival" }),
              let firstInfo = firstStop.stopinfo, let lastInfo = lastStop.stopinfo,
              let firstLat = firstInfo.latitude, let firstLon = firstInfo.longitude,
              let lastLat = lastInfo.latitude, let lastLon = lastInfo.longitude else { return nil }

        let firstCoord = CLLocationCoordinate2D(latitude: firstLat, longitude: firstLon)
        let lastCoord = CLLocationCoordinate2D(latitude: lastLat, longitude: lastLon)

        return routes.first { route in
            route.stopCoordinates.first == firstCoord && route.stopCoordinates.last == lastCoord
        }
    }
}
