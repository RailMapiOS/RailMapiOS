//
//  RouteGeometryClient.swift
//  RailMapiOS
//
//  Thin TCA adapter for RouteGeometryService.
//

import CoreLocation
import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct RouteGeometryClient {
    var fetchRouteShape: @Sendable (_ trainNumber: String, _ source: String, _ tripID: String?) async throws -> TrainShapeResult
    var fetchRouteGeometry: @Sendable (_ stops: [CLLocationCoordinate2D]) async throws -> [CLLocationCoordinate2D] = { stops in stops }
}

extension RouteGeometryClient: DependencyKey {
    static let liveValue: Self = {
        let service = RouteGeometryService()
        return Self(
            fetchRouteShape: { try await service.fetchRouteShape(trainNumber: $0, source: $1, tripID: $2) },
            fetchRouteGeometry: { try await service.fetchRouteGeometry(for: $0) }
        )
    }()
}

extension DependencyValues {
    var routeGeometryClient: RouteGeometryClient {
        get { self[RouteGeometryClient.self] }
        set { self[RouteGeometryClient.self] = newValue }
    }
}
