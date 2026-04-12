//
//  JourneyRowViewModel.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 26/07/2024.
//

import Foundation
import SwiftUI
import SwiftData

enum JourneyStatus {
    case upcoming, inProgress, completed, delayed, cancelled

    var label: String {
        switch self {
        case .upcoming: return "Upcoming"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .delayed: return "Delayed"
        case .cancelled: return "Cancelled"
        }
    }
}

// MARK: - Saved Journey Data Source

@MainActor
final class SavedJourneyDataSource: JourneyRowDataSource {
    private let journey: Journey
    private let dateFormatterService: DateFormatterServiceProtocol
    private let journeyDataService: JourneyDataServiceProtocol

    @Published private(set) var headsign: String
    @Published private(set) var company: String
    @Published private(set) var duration: String
    @Published private(set) var primaryLeft: String
    @Published private(set) var primaryLeftColor: Color = .primary
    @Published private(set) var secondaryLeft: String
    @Published private(set) var primaryRight: String
    @Published private(set) var primaryRightColor: Color = .primary
    @Published private(set) var secondaryRight: String
    @Published private(set) var footer: JourneyRowFooter

    init(
        journey: Journey,
        dateFormatterService: DateFormatterServiceProtocol = DateFormatterService(),
        journeyDataService: JourneyDataServiceProtocol = JourneyDataService()
    ) {
        self.journey = journey
        self.dateFormatterService = dateFormatterService
        self.journeyDataService = journeyDataService

        self.headsign = journey.headsign ?? "N/A"
        self.company = journey.company ?? "N/A"
        self.duration = ""
        self.primaryLeft = ""
        self.secondaryLeft = ""
        self.primaryRight = ""
        self.secondaryRight = ""
        self.footer = .saved(date: "", status: .upcoming)

        self.loadData()
    }

    private func loadData() {
        let departureStop = journeyDataService.getDepartureStop(journey)
        let arrivalStop = journeyDataService.getArrivalStop(journey)

        self.primaryLeft = dateFormatterService.formatJourneyTime(journey.startDate)
        self.secondaryLeft = departureStop?.stopinfo?.label ?? "N/A"
        self.primaryRight = dateFormatterService.formatJourneyTime(journey.endDate)
        self.secondaryRight = arrivalStop?.stopinfo?.label ?? "N/A"

        self.duration = dateFormatterService.calculateDuration(
            startDate: journey.startDate,
            endDate: journey.endDate
        )

        let status = Self.deriveStatus(startDate: journey.startDate, endDate: journey.endDate)
        let date = dateFormatterService.formatJourneyDate(journey.startDate)
        self.footer = .saved(date: date, status: status)
    }

    static func deriveStatus(startDate: Date?, endDate: Date?) -> JourneyStatus {
        let now = Date()
        guard let start = startDate else { return .upcoming }
        guard let end = endDate else {
            return now < start ? .upcoming : .completed
        }
        if now < start { return .upcoming }
        if now >= start && now <= end { return .inProgress }
        return .completed
    }
}

// MARK: - Search Journey Data Source

@MainActor
final class SearchJourneyDataSource: JourneyRowDataSource {
    private let journey: VehicleJourney
    private let dateFormatterService: DateFormatterServiceProtocol

    @Published private(set) var headsign: String
    @Published private(set) var company: String
    @Published private(set) var duration: String
    @Published private(set) var primaryLeft: String
    @Published private(set) var primaryLeftColor: Color
    @Published private(set) var secondaryLeft: String
    @Published private(set) var primaryRight: String
    @Published private(set) var primaryRightColor: Color
    @Published private(set) var secondaryRight: String
    @Published private(set) var footer: JourneyRowFooter

    init(
        journey: VehicleJourney,
        departureStationID: String? = nil,
        arrivalStationID: String? = nil,
        dateFormatterService: DateFormatterServiceProtocol = DateFormatterService()
    ) {
        self.journey = journey
        self.dateFormatterService = dateFormatterService

        self.headsign = journey.headsign
        self.company = Self.resolveCompany(from: journey)
        self.duration = Self.calculateDuration(from: journey, formatter: dateFormatterService)
        self.footer = .none

        // Resolve station names and colors
        let resolved = Self.resolveStations(
            journey: journey,
            departureStationID: departureStationID,
            arrivalStationID: arrivalStationID,
            formatter: dateFormatterService
        )
        self.primaryLeft = resolved.departureName
        self.primaryLeftColor = resolved.departureColor
        self.secondaryLeft = resolved.departureTime
        self.primaryRight = resolved.arrivalName
        self.primaryRightColor = resolved.arrivalColor
        self.secondaryRight = resolved.arrivalTime
    }

    /// Updates the displayed stations and recalculates duration when the user picks departure/arrival.
    func updateStations(departureStationID: String?, arrivalStationID: String?) {
        let resolved = Self.resolveStations(
            journey: journey,
            departureStationID: departureStationID,
            arrivalStationID: arrivalStationID,
            formatter: dateFormatterService
        )
        self.primaryLeft = resolved.departureName
        self.primaryLeftColor = resolved.departureColor
        self.secondaryLeft = resolved.departureTime
        self.primaryRight = resolved.arrivalName
        self.primaryRightColor = resolved.arrivalColor
        self.secondaryRight = resolved.arrivalTime

        // Recalculate duration between selected stations
        if let depID = departureStationID,
           let arrID = arrivalStationID,
           let depStop = journey.stopTimes.first(where: { $0.stopPoint.id == depID }),
           let arrStop = journey.stopTimes.first(where: { $0.stopPoint.id == arrID }) {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HHmmss"
            if let depDate = timeFormatter.date(from: depStop.departureTime),
               let arrDate = timeFormatter.date(from: arrStop.arrivalTime) {
                self.duration = dateFormatterService.calculateDuration(startDate: depDate, endDate: arrDate)
            }
        }
    }

    // MARK: - Private

    private static func resolveStations(
        journey: VehicleJourney,
        departureStationID: String?,
        arrivalStationID: String?,
        formatter: DateFormatterServiceProtocol
    ) -> (departureName: String, departureTime: String, departureColor: Color,
          arrivalName: String, arrivalTime: String, arrivalColor: Color) {

        let depStop: StopTime?
        let depColor: Color
        if let depID = departureStationID,
           let match = journey.stopTimes.first(where: { $0.stopPoint.id == depID }) {
            depStop = match
            depColor = .primary
        } else {
            depStop = journey.stopTimes.first
            depColor = .secondary
        }

        let arrStop: StopTime?
        let arrColor: Color
        if let arrID = arrivalStationID,
           let match = journey.stopTimes.first(where: { $0.stopPoint.id == arrID }) {
            arrStop = match
            arrColor = .primary
        } else {
            arrStop = journey.stopTimes.last
            arrColor = .secondary
        }

        return (
            departureName: depStop?.stopPoint.name ?? "N/A",
            departureTime: formatter.formattedHour(from: depStop?.departureTime ?? ""),
            departureColor: depColor,
            arrivalName: arrStop?.stopPoint.name ?? "N/A",
            arrivalTime: formatter.formattedHour(from: arrStop?.arrivalTime ?? ""),
            arrivalColor: arrColor
        )
    }

    static func companyName(from journey: VehicleJourney) -> String? {
        let name = resolveCompany(from: journey)
        return name == "N/A" ? nil : name
    }

    private static func resolveCompany(from journey: VehicleJourney) -> String {
        guard let stopPointId = journey.stopTimes.first?.stopPoint.id else { return "N/A" }
        let parts = stopPointId.components(separatedBy: " ")
        if parts.count > 1, let company = parts[1].components(separatedBy: "-").first {
            return company
        }
        return "N/A"
    }

    private static func calculateDuration(
        from journey: VehicleJourney,
        formatter: DateFormatterServiceProtocol
    ) -> String {
        guard let depTime = journey.stopTimes.first?.departureTime,
              let arrTime = journey.stopTimes.last?.arrivalTime else { return "N/A" }

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HHmmss"
        guard let depDate = timeFormatter.date(from: depTime),
              let arrDate = timeFormatter.date(from: arrTime) else { return "N/A" }

        return formatter.calculateDuration(startDate: depDate, endDate: arrDate)
    }
}
