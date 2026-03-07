//
//  JourneyRowViewModel.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 26/07/2024.
//

import Foundation
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

@MainActor
final class JourneyRowViewModel: ObservableObject {
    private let journey: Journey
    private let dateFormatterService: DateFormatterServiceProtocol
    private let journeyDataService: JourneyDataServiceProtocol

    @Published private(set) var headsign: String
    @Published private(set) var departureTime: String
    @Published private(set) var departureDate: String
    @Published private(set) var departureLabel: String
    @Published private(set) var arrivalTime: String
    @Published private(set) var arrivalDate: String
    @Published private(set) var arrivalLabel: String
    @Published private(set) var company: String
    @Published private(set) var duration: String
    @Published private(set) var status: JourneyStatus

    init(
        journey: Journey,
        dateFormatterService: DateFormatterServiceProtocol = DateFormatterService(),
        journeyDataService: JourneyDataServiceProtocol = JourneyDataService()
    ) {
        self.journey = journey
        self.dateFormatterService = dateFormatterService
        self.journeyDataService = journeyDataService

        self.headsign = journey.headsign ?? "N/A"
        self.departureTime = ""
        self.departureDate = ""
        self.departureLabel = ""
        self.arrivalTime = ""
        self.arrivalDate = ""
        self.arrivalLabel = ""
        self.company = ""
        self.duration = ""
        self.status = .upcoming

        self.loadJourneyData()
    }

    private func loadJourneyData() {
        let departureStop = journeyDataService.getDepartureStop(journey)
        let arrivalStop = journeyDataService.getArrivalStop(journey)

        self.departureTime = dateFormatterService.formatJourneyTime(journey.startDate)
        self.departureDate = dateFormatterService.formatJourneyDate(journey.startDate)
        self.departureLabel = departureStop?.stopinfo?.label ?? "N/A"

        self.arrivalTime = dateFormatterService.formatJourneyTime(journey.endDate)
        self.arrivalDate = dateFormatterService.formatJourneyDate(journey.endDate)
        self.arrivalLabel = arrivalStop?.stopinfo?.label ?? "N/A"

        self.company = journey.company ?? "N/A"
        self.duration = dateFormatterService.calculateDuration(
            startDate: journey.startDate,
            endDate: journey.endDate
        )
        self.status = Self.deriveStatus(startDate: journey.startDate, endDate: journey.endDate)
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
