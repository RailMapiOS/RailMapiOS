//
//  RouteGeometryService.swift
//  RailMapiOS
//
//  Pure business logic service for train route shape fetching.
//  Cascades through GTFS shapes → signal.eu.org OSRM → Overpass → stop-to-stop.
//

import CoreLocation
import Foundation

// MARK: - Result

struct TrainShapeResult: Sendable {
    let coordinates: [CLLocationCoordinate2D]
    /// "gtfs", "signal-osrm", "overpass", or "stops-only"
    let shapeSource: String
}

// MARK: - Service

struct RouteGeometryService: Sendable {
    let baseURL: String

    init(baseURL: String = "http://127.0.0.1:8080") {
        self.baseURL = baseURL
    }

    /// Fetches the route shape for a specific train number from RailMapAPI.
    func fetchRouteShape(trainNumber: String, source: String) async throws -> TrainShapeResult {
        let encodedTrain = trainNumber.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? trainNumber
        guard let url = URL(string: "\(baseURL)/train/\(encodedTrain)/shape?source=\(source)") else {
            throw ServiceError.invalidURL
        }
        let (data, response) = try await URLSession.shared.data(for: URLRequest(url: url))
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw ServiceError.serverError(response)
        }
        let decoded = try JSONDecoder().decode(TrainShapeAPIResponse.self, from: data)
        let coordinates = decoded.geojson.coordinates.compactMap { pair -> CLLocationCoordinate2D? in
            guard pair.count >= 2 else { return nil }
            return CLLocationCoordinate2D(latitude: pair[1], longitude: pair[0])
        }
        return TrainShapeResult(coordinates: coordinates, shapeSource: decoded.shapeSource)
    }

    /// Fallback: fetches route geometry from signal.eu.org OSRM using stop coordinates as waypoints.
    func fetchRouteGeometry(for stops: [CLLocationCoordinate2D]) async throws -> [CLLocationCoordinate2D] {
        guard stops.count >= 2 else { return stops }
        let waypoints = stops.map { "\($0.longitude),\($0.latitude)" }.joined(separator: ";")
        let urlString = "https://signal.eu.org/osm/eu/route/v1/train/\(waypoints)?overview=full&geometries=geojson"
        guard let url = URL(string: urlString) else { throw ServiceError.invalidURL }
        let (data, response) = try await URLSession.shared.data(for: URLRequest(url: url))
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw ServiceError.serverError(response)
        }
        let decoded = try JSONDecoder().decode(OSRMDirectResponse.self, from: data)
        guard decoded.code == "Ok", let route = decoded.routes.first else { return stops }
        return route.geometry.coordinates.compactMap { pair -> CLLocationCoordinate2D? in
            guard pair.count >= 2 else { return nil }
            return CLLocationCoordinate2D(latitude: pair[1], longitude: pair[0])
        }
    }
}

// MARK: - DTOs (private to file)

private struct TrainShapeAPIResponse: Decodable {
    let trainNumber: String
    let source: String
    let shapeSource: String
    let geojson: GeoJSONResponse

    enum CodingKeys: String, CodingKey {
        case trainNumber = "train_number"
        case source
        case shapeSource = "shape_source"
        case geojson
    }
}

private struct GeoJSONResponse: Decodable {
    let type: String
    let coordinates: [[Double]]
}

private struct OSRMDirectResponse: Decodable {
    let code: String
    let routes: [OSRMRouteResponse]
}

private struct OSRMRouteResponse: Decodable {
    let geometry: OSRMGeometryResponse
}

private struct OSRMGeometryResponse: Decodable {
    let type: String
    let coordinates: [[Double]]
}
