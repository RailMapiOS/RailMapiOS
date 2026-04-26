//
//  MapClient.swift
//  RailMapiOS
//
//  Thin TCA adapter for MapService.
//

import CoreLocation
import Dependencies
import DependenciesMacros
import Foundation
import MapKit

@DependencyClient
struct MapClient {
    var generateTrainRoutes: @Sendable (_ journeys: [Journey]) -> [TrainRoute] = { _ in [] }
    var regionEncompassing: @Sendable (_ routes: [TrainRoute], _ padding: CGFloat) -> MKCoordinateRegion?
    var regionForCoordinates: @Sendable (_ coords: [CLLocationCoordinate2D], _ padding: CGFloat) -> MKCoordinateRegion?
    var findMatchingRoute: @Sendable (_ journey: Journey, _ routes: [TrainRoute]) -> TrainRoute?
}

extension MapClient: DependencyKey {
    static let liveValue: Self = {
        let service = MapService()
        return Self(
            generateTrainRoutes: { service.generateTrainRoutes(from: $0) },
            regionEncompassing: { service.regionEncompassing(routes: $0, padding: $1) },
            regionForCoordinates: { service.region(for: $0, padding: $1) },
            findMatchingRoute: { service.findMatchingRoute(for: $0, in: $1) }
        )
    }()
}

extension DependencyValues {
    var mapClient: MapClient {
        get { self[MapClient.self] }
        set { self[MapClient.self] = newValue }
    }
}
