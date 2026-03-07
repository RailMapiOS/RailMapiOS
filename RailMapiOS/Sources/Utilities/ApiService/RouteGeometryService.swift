//
//  RouteGeometryService.swift
//  RailMapiOS
//
//  Created by Claude on 07/03/2026.
//

import Foundation
import CoreLocation

actor RouteGeometryService {
    static let shared = RouteGeometryService()

    private let baseURL: String

    init(baseURL: String = "http://127.0.0.1:8080") {
        self.baseURL = baseURL
    }

    /// Fetches rail route geometry for a list of stop coordinates.
    /// Returns a detailed polyline following real rail tracks via signal.eu.org OSRM.
    func fetchRouteGeometry(for stops: [CLLocationCoordinate2D]) async throws -> [CLLocationCoordinate2D] {
        guard stops.count >= 2 else { return stops }

        // Build waypoints param: lon1,lat1;lon2,lat2;...
        let waypoints = stops.map { "\($0.longitude),\($0.latitude)" }.joined(separator: ";")
        let urlString = "\(baseURL)/route/geometry?waypoints=\(waypoints)"

        guard let url = URL(string: urlString) else {
            throw ServiceError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(for: URLRequest(url: url))

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            throw ServiceError.serverError(response)
        }

        let decoded = try JSONDecoder().decode(RouteGeometryResponse.self, from: data)

        // Convert [[lon, lat], ...] to [CLLocationCoordinate2D]
        return decoded.coordinates.compactMap { pair in
            guard pair.count >= 2 else { return nil }
            return CLLocationCoordinate2D(latitude: pair[1], longitude: pair[0])
        }
    }
}

private struct RouteGeometryResponse: Decodable {
    let coordinates: [[Double]]
}
