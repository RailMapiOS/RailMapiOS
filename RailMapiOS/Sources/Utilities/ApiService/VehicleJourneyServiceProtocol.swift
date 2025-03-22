//
//  VehicleJourneyServiceProtocol.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 21/03/2025.
//

import Foundation

@preconcurrency
protocol VehicleJourneyServiceProtocol {
    func fetchVehicleJourneys(headsign: String) async throws -> [VehicleJourney]
    func getPassageDays(from vehicleJourneys: [VehicleJourney]) -> [String: [Date]]
}

actor VehicleJourneyService: VehicleJourneyServiceProtocol {
    private let baseURL: String
    
    init(baseURL: String = "http://127.0.0.1:8080") {
        self.baseURL = baseURL
    }
    
    func fetchVehicleJourneys(headsign: String) async throws -> [VehicleJourney] {
        let urlString = "\(baseURL)/stop/\(headsign)?agency=sncf&serviceType=tgv"
        
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

enum ServiceError: Error {
    case invalidURL
    case serverError(URLResponse)
    case decodingError(Error)
}

extension VehicleJourney: @unchecked Sendable {}
