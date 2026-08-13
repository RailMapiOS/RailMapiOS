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

            var route = TrainRoute(
                id: journey.id ?? UUID(),
                coordinates: coordinates,
                company: journey.company,
                headsign: journey.headsign,
                isPast: journey.isPast
            )
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

    /// Finds the route generated from `journey`.
    ///
    /// Routes carry their journey's id, so this is an exact lookup. The
    /// departure/arrival coordinate match below is only a fallback for
    /// journeys that have no id yet (never persisted): on its own it picks the
    /// first route sharing the same origin and destination, which is the wrong
    /// trip as soon as the user has saved the same route twice.
    func findMatchingRoute(for journey: Journey, in routes: [TrainRoute]) -> TrainRoute? {
        if let journeyID = journey.id, let exact = routes.first(where: { $0.id == journeyID }) {
            return exact
        }

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
