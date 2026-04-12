//
//  VehicleJourneyService.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 21/03/2025.
//

import Foundation

@preconcurrency
protocol VehicleJourneyServiceProtocol: Sendable {
    func fetchVehicleJourneys(headsign: String, source: String) async throws -> [VehicleJourney]
    func fetchTrainInfo(trainNumber: String, source: String?) async throws -> TrainInfoResult
    func getPassageDays(from vehicleJourneys: [VehicleJourney]) -> [String: [Date]]
}

actor VehicleJourneyService: VehicleJourneyServiceProtocol {
    private let baseURL: String

    init(baseURL: String = "http://127.0.0.1:8080") {
        self.baseURL = baseURL
    }

    /// Fetches vehicle journeys for a headsign from a specific data source.
    /// - Parameters:
    ///   - headsign: The train headsign (e.g. destination name)
    ///   - source: The data source identifier (e.g. "sncf-ter", "sncf-tgv", "db")
    func fetchVehicleJourneys(headsign: String, source: String = "sncf-ter") async throws -> [VehicleJourney] {
        let encodedHeadsign = headsign.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? headsign
        let urlString = "\(baseURL)/stop/\(encodedHeadsign)?source=\(source)"

        guard let url = URL(string: urlString) else {
            throw ServiceError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(for: URLRequest(url: url))

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw ServiceError.serverError(response)
        }

        let decoder = JSONDecoder()
        let decodedResponse = try decoder.decode(VehicleJourneys.self, from: data)

        return decodedResponse.vehicleJourneys
    }

    /// Resolves service type info for a train number.
    /// - Parameters:
    ///   - trainNumber: The train number (trip_short_name in GTFS)
    ///   - source: Optional data source to search in. If nil, searches all sources.
    func fetchTrainInfo(trainNumber: String, source: String? = nil) async throws -> TrainInfoResult {
        let encodedTrain = trainNumber.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? trainNumber
        var urlString = "\(baseURL)/train/\(encodedTrain)"
        if let source {
            urlString += "?source=\(source)"
        }

        guard let url = URL(string: urlString) else {
            throw ServiceError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(for: URLRequest(url: url))

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw ServiceError.serverError(response)
        }

        return try JSONDecoder().decode(TrainInfoResult.self, from: data)
    }

    nonisolated func getPassageDays(from vehicleJourneys: [VehicleJourney]) -> [String: [Date]] {
        var passageDays: [String: [Date]] = [:]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        for journey in vehicleJourneys {
            passageDays[journey.id] = []

            for calendar in journey.calendars {
                // Process each active period
                for period in calendar.activePeriods {
                    guard let startDate = dateFormatter.date(from: period.begin),
                          let endDate = dateFormatter.date(from: period.end) else {
                        continue
                    }

                    var currentDate = startDate
                    while currentDate <= endDate {
                        let weekday = Calendar.current.component(.weekday, from: currentDate)

                        // Check week pattern
                        let isValidDay = (weekday == 1 && calendar.weekPattern.sunday) ||
                        (weekday == 2 && calendar.weekPattern.monday) ||
                        (weekday == 3 && calendar.weekPattern.tuesday) ||
                        (weekday == 4 && calendar.weekPattern.wednesday) ||
                        (weekday == 5 && calendar.weekPattern.thursday) ||
                        (weekday == 6 && calendar.weekPattern.friday) ||
                        (weekday == 7 && calendar.weekPattern.saturday)

                        if isValidDay {
                            passageDays[journey.id]?.append(currentDate)
                        }

                        currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
                    }
                }

                // Process exceptions
                if let exceptions = calendar.exceptions {
                    for exception in exceptions {
                        if let exceptionDate = dateFormatter.date(from: exception.datetime) {
                            switch exception.type {
                            case .add:
                                if !passageDays[journey.id]!.contains(exceptionDate) {
                                    passageDays[journey.id]?.append(exceptionDate)
                                }
                            case .remove:
                                passageDays[journey.id]?.removeAll { $0 == exceptionDate }
                            }
                        }
                    }
                }
            }

            // Sort dates
            passageDays[journey.id]?.sort()
        }

        return passageDays
    }
}

// MARK: - Train Info DTOs

struct TrainInfoResult: Decodable {
    let trainNumber: String
    let results: [TrainInfoItem]

    enum CodingKeys: String, CodingKey {
        case trainNumber = "train_number"
        case results
    }
}

struct TrainInfoItem: Decodable, Identifiable {
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

enum ServiceError: Error {
    case invalidURL
    case serverError(URLResponse)
    case decodingError(Error)
}

extension VehicleJourney: @unchecked Sendable {}
