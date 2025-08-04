//
//  JourneyRowViewModel.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 26/07/2024.
//

import Foundation
import SwiftData

@MainActor
final class JourneyRowViewModel: ObservableObject {
    private let journey: JourneySD
    private let dateFormatterService: DateFormatterServiceProtocol
    private let journeyDataService: JourneyDataServiceProtocol
    
    @Published private(set) var headsign: String
    @Published private(set) var departureTime: String
    @Published private(set) var departureDate: String
    @Published private(set) var departureLabel: String
    @Published private(set) var arrivalTime: String
    @Published private(set) var arrivalDate: String
    @Published private(set) var arrivalLabel: String
    @Published private(set) var compagny: String
    @Published private(set) var duration: String
    
    init(
        journey: JourneySD,
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
        self.compagny = ""
        self.duration = ""
        
        self.loadJourneyData()
        LogManager.info("Initialisation de JourneyRowViewModel pour le trajet vers \(journey.headsign ?? "destination inconnue")")
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
        
        self.compagny = journey.company ?? "N/A"
        self.duration = dateFormatterService.calculateDuration(
            startDate: journey.startDate,
            endDate: journey.endDate
        )
    }
}
