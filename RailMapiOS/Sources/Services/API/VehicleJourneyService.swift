//
//  VehicleJourneyService.swift
//  RailMapiOS
//
//  Pure business logic service for vehicle journey API.
//  Stateless, testable, independent of TCA.
//

import Foundation

// MARK: - Errors & DTOs

enum ServiceError: Error, Sendable {
    case invalidURL
    case serverError(URLResponse)
    case decodingError(Error)
}

struct TrainInfoResult: Decodable, Sendable {
    let trainNumber: String
    let results: [TrainInfoItem]

    enum CodingKeys: String, CodingKey {
        case trainNumber = "train_number"
        case results
    }
}

struct TrainInfoItem: Decodable, Identifiable, Sendable {
    var id: String { tripID }
    let trainNumber: String
    let source: String
    let sourceDisplayName: String
    let tripID: String
    let routeID: String
    let routeShortName: String?
    let routeLongName: String?
    let routeType: UInt
    let routeTypeDescription: String
    let agencyID: String?
    let agencyName: String
    let headsign: String?
    let direction: String?

    enum CodingKeys: String, CodingKey {
        case trainNumber = "train_number"
        case source
        case sourceDisplayName = "source_display_name"
        case tripID = "trip_id"
        case routeID = "route_id"
        case routeShortName = "route_short_name"
        case routeLongName = "route_long_name"
        case routeType = "route_type"
        case routeTypeDescription = "route_type_description"
        case agencyID = "agency_id"
        case agencyName = "agency_name"
        case headsign
        case direction
    }
}

extension VehicleJourney: @unchecked Sendable {}

// MARK: - Service

/// Business service for vehicle journey API operations.
/// Uses URLSession directly. Pure functions for calendar parsing.
struct VehicleJourneyService: Sendable {
    let baseURL: String

    init(baseURL: String = APIConfiguration.baseURL) {
        self.baseURL = baseURL
    }

    // MARK: - API

    func fetchVehicleJourneys(headsign: String, source: String) async throws -> [VehicleJourney] {
        let encodedHeadsign = headsign.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? headsign
        guard let url = URL(string: "\(baseURL)/stop/\(encodedHeadsign)?source=\(source)") else {
            throw ServiceError.invalidURL
        }
        let (data, response) = try await URLSession.shared.data(for: .authorized(url))
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw ServiceError.serverError(response)
        }
        return try JSONDecoder().decode(VehicleJourneys.self, from: data).vehicleJourneys
    }

    func fetchTrainInfo(trainNumber: String, source: String?) async throws -> TrainInfoResult {
        let encodedTrain = trainNumber.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? trainNumber
        var urlString = "\(baseURL)/train/\(encodedTrain)"
        if let source { urlString += "?source=\(source)" }
        guard let url = URL(string: urlString) else { throw ServiceError.invalidURL }
        let (data, response) = try await URLSession.shared.data(for: .authorized(url))
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw ServiceError.serverError(response)
        }
        return try JSONDecoder().decode(TrainInfoResult.self, from: data)
    }

    // MARK: - Calendar parsing (pure logic)

    /// Computes all passage days for each journey from its calendar pattern + exceptions.
    func passageDays(from journeys: [VehicleJourney]) -> [String: [Date]] {
        var passageDays: [String: [Date]] = [:]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        for journey in journeys {
            passageDays[journey.id] = []

            for cal in journey.calendars {
                for period in cal.activePeriods {
                    guard let startDate = dateFormatter.date(from: period.begin),
                          let endDate = dateFormatter.date(from: period.end) else { continue }

                    var current = startDate
                    while current <= endDate {
                        let weekday = Calendar.current.component(.weekday, from: current)
                        if Self.isWeekdayActive(weekday, in: cal.weekPattern) {
                            passageDays[journey.id]?.append(current)
                        }
                        current = Calendar.current.date(byAdding: .day, value: 1, to: current) ?? current
                    }
                }

                if let exceptions = cal.exceptions {
                    for exception in exceptions {
                        guard let date = dateFormatter.date(from: exception.datetime) else { continue }
                        switch exception.type {
                        case .add:
                            if !(passageDays[journey.id]?.contains(date) ?? true) {
                                passageDays[journey.id]?.append(date)
                            }
                        case .remove:
                            passageDays[journey.id]?.removeAll { $0 == date }
                        }
                    }
                }
            }
            passageDays[journey.id]?.sort()
        }
        return passageDays
    }

    private static func isWeekdayActive(_ weekday: Int, in pattern: WeekPattern) -> Bool {
        switch weekday {
        case 1: return pattern.sunday
        case 2: return pattern.monday
        case 3: return pattern.tuesday
        case 4: return pattern.wednesday
        case 5: return pattern.thursday
        case 6: return pattern.friday
        case 7: return pattern.saturday
        default: return false
        }
    }
}
