//
//  RouteGeometryClient.swift
//  RailMapiOS
//
//  TCA Dependency wrapping RouteGeometryService.
//

import CoreLocation
import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct RouteGeometryClient {
    var fetchRouteShape: @Sendable (_ trainNumber: String, _ source: String) async throws -> TrainShapeResult
    var fetchRouteGeometry: @Sendable (_ stops: [CLLocationCoordinate2D]) async throws -> [CLLocationCoordinate2D] = { stops in stops }
}

extension RouteGeometryClient: DependencyKey {
    static let liveValue: Self = {
        let service = RouteGeometryService.shared
        return Self(
            fetchRouteShape: { trainNumber, source in
                try await service.fetchRouteShape(trainNumber: trainNumber, source: source)
            },
            fetchRouteGeometry: { stops in
                try await service.fetchRouteGeometry(for: stops)
            }
        )
    }()
}

extension DependencyValues {
    var routeGeometryClient: RouteGeometryClient {
        get { self[RouteGeometryClient.self] }
        set { self[RouteGeometryClient.self] = newValue }
    }
}
