//
//  RealtimeService.swift
//  RailMapiOS
//
//  GTFS-Realtime API client. Fetches trip updates, vehicle positions and alerts
//  from the RailMapAPI `/realtime/*` endpoints.
//
//  DTOs strictly match the server contract (camelCase property names — Vapor's
//  `Content` default; no CodingKeys overrides) so JSONDecoder maps 1:1.
//

import CoreLocation
import Foundation

// MARK: - DTOs (mirror RailMapAPI/Sources/App/Realtime/RealtimeDTO.swift)

/// Wrapper response when fetching all trip updates for a source.
struct TripUpdatesResponseDTO: Codable, Sendable {
    let source: String
    let tripUpdates: [TripUpdateDTO]
}

/// Single trip update — matches `TripUpdateDTO` server-side.
struct TripUpdateDTO: Codable, Equatable, Sendable {
    let tripID: String
    let routeID: String?
    /// Raw `scheduleRelationship` as Int — see GTFS-RT enum: 0=SCHEDULED, 1=ADDED, 2=UNSCHEDULED, 3=CANCELED.
    let scheduleRelationship: Int
    let delay: Int32?
    let timestamp: Date
    let vehicleID: String?
    let stopTimeUpdates: [StopTimeUpdateDTO]

    /// True if the API marks this trip as canceled.
    var isCancelled: Bool { scheduleRelationship == 3 }
}

struct StopTimeUpdateDTO: Codable, Equatable, Sendable {
    let stopID: String
    let stopSequence: UInt32?
    let arrivalDelay: Int32?
    let arrivalTime: Date?
    let departureDelay: Int32?
    let departureTime: Date?
    let scheduleRelationship: Int
    /// Announced platform / track number, resolved server-side from the
    /// static GTFS feed when the operator redirects `stopID` from a parent
    /// `stop_area` to a child stop carrying `platform_code`. `nil` when not
    /// yet announced or when the operator never publishes the platform.
    let platform: String?
}

// MARK: - Alerts

struct AlertsResponseDTO: Codable, Sendable {
    let source: String
    let alerts: [AlertDTO]
}

struct AlertDTO: Codable, Equatable, Sendable {
    let alertID: String
    let cause: Int?
    let effect: Int?
    let url: String?
    let headerText: String?
    let descriptionText: String?
    let activePeriods: [TimePeriodDTO]
    let informedEntities: [EntityDTO]

    /// True when this alert affects the given trip ID (informed-entity scoped).
    func affects(tripID: String) -> Bool {
        informedEntities.contains { $0.tripID == tripID }
    }

    /// Permissive matching for line-wide / station-wide alerts that don't
    /// carry a specific tripID (typical for SNCF TER disruptions, where the
    /// alert is scoped to the Line UUID and/or affected stops only).
    func affects(tripID: String? = nil, routeID: String? = nil, stopIDs: Set<String> = []) -> Bool {
        informedEntities.contains { entity in
            if let tripID, entity.tripID == tripID { return true }
            if let routeID, entity.routeID == routeID { return true }
            if let stop = entity.stopID, stopIDs.contains(stop) { return true }
            return false
        }
    }
}

struct TimePeriodDTO: Codable, Equatable, Sendable {
    let start: Date?
    let end: Date?
}

struct EntityDTO: Codable, Equatable, Sendable {
    let agencyID: String?
    let routeID: String?
    let routeType: Int32?
    let tripID: String?
    let stopID: String?
    let directionID: UInt32?
}

// MARK: - Vehicle Positions

struct VehiclePositionsResponseDTO: Codable, Sendable {
    let source: String
    let vehiclePositions: [VehiclePositionDTO]
}

struct VehiclePositionDTO: Codable, Equatable, Sendable {
    let tripID: String?
    let vehicleID: String
    let latitude: Double?
    let longitude: Double?
    let bearing: Float?
    let speed: Float?
    let currentStopSequence: UInt32?
    let currentStatus: Int
    let timestamp: Date
    let occupancyStatus: Int?
}

// MARK: - Service

struct RealtimeService: Sendable {
    let baseURL: String

    init(baseURL: String = APIConfiguration.baseURL) {
        self.baseURL = baseURL
    }

    /// Fetches the live trip update for a given trip ID.
    /// Returns nil if the API has no entry for it (404).
    func fetchTripUpdate(tripID: String, source: String) async throws -> TripUpdateDTO? {
        let encoded = tripID.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? tripID
        guard let url = URL(string: "\(baseURL)/realtime/trip-updates/\(encoded)?source=\(source)") else {
            throw ServiceError.invalidURL
        }
        let (data, response) = try await URLSession.shared.data(for: .authorized(url))
        guard let http = response as? HTTPURLResponse else { throw ServiceError.serverError(response) }
        if http.statusCode == 404 { return nil }
        guard (200...299).contains(http.statusCode) else { throw ServiceError.serverError(response) }
        return try Self.decoder.decode(TripUpdateDTO.self, from: data)
    }

    /// Fetches the live vehicle position for a given trip ID.
    /// The server endpoint returns ALL positions for a source — we filter by trip_id locally.
    func fetchVehiclePosition(tripID: String, source: String) async throws -> VehiclePositionDTO? {
        guard let url = URL(string: "\(baseURL)/realtime/vehicle-positions?source=\(source)") else {
            throw ServiceError.invalidURL
        }
        let (data, response) = try await URLSession.shared.data(for: .authorized(url))
        guard let http = response as? HTTPURLResponse else { throw ServiceError.serverError(response) }
        if http.statusCode == 404 { return nil }
        guard (200...299).contains(http.statusCode) else { throw ServiceError.serverError(response) }
        let envelope = try Self.decoder.decode(VehiclePositionsResponseDTO.self, from: data)
        return envelope.vehiclePositions.first { $0.tripID == tripID }
    }

    /// Fetches active alerts for a source. Optionally filters by trip ID.
    func fetchAlerts(source: String, tripID: String? = nil) async throws -> [AlertDTO] {
        guard let url = URL(string: "\(baseURL)/realtime/alerts?source=\(source)") else {
            throw ServiceError.invalidURL
        }
        let (data, response) = try await URLSession.shared.data(for: .authorized(url))
        guard let http = response as? HTTPURLResponse else { throw ServiceError.serverError(response) }
        guard (200...299).contains(http.statusCode) else { throw ServiceError.serverError(response) }
        let envelope = try Self.decoder.decode(AlertsResponseDTO.self, from: data)
        guard let tripID else { return envelope.alerts }
        return envelope.alerts.filter { $0.affects(tripID: tripID) }
    }

    /// JSON decoder configured to match the API's date encoding (Vapor default = ISO8601 / seconds-since-1970).
    /// We try ISO8601 first then fall back to seconds.
    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { d in
            let container = try d.singleValueContainer()
            if let s = try? container.decode(String.self) {
                let iso = ISO8601DateFormatter()
                iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let date = iso.date(from: s) { return date }
                iso.formatOptions = [.withInternetDateTime]
                if let date = iso.date(from: s) { return date }
            }
            if let n = try? container.decode(Double.self) {
                return Date(timeIntervalSince1970: n)
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unrecognized date format")
        }
        return decoder
    }()
}
