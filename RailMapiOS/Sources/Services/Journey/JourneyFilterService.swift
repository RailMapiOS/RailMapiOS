//
//  JourneyFilterService.swift
//  RailMapiOS
//
//  Pure business logic for filtering and transforming journeys.
//  Stateless, testable.
//

import Foundation

struct JourneyFilterService: Sendable {
    private let vehicleJourneyService: VehicleJourneyService

    init(vehicleJourneyService: VehicleJourneyService = VehicleJourneyService()) {
        self.vehicleJourneyService = vehicleJourneyService
    }

    /// Filters saved journeys by search text (case-insensitive headsign match).
    func filter(journeys: [Journey], by searchText: String) -> [Journey] {
        guard !searchText.isEmpty else { return journeys }
        return journeys.filter { journey in
            guard let headsign = journey.headsign else { return false }
            return headsign.localizedCaseInsensitiveContains(searchText)
        }
    }

    /// Builds DateRows from VehicleJourneys, merging passage days from all journeys
    /// and filtering out past dates.
    func buildDateRows(
        from vehicleJourneys: [VehicleJourney],
        departureStationID: String?,
        arrivalStationID: String?
    ) -> [DateRow] {
        guard let referenceJourney = vehicleJourneys.first else { return [] }
        let passageDays = vehicleJourneyService.passageDays(from: vehicleJourneys)
        let today = Calendar.current.startOfDay(for: Date())

        let allDates = passageDays.values.flatMap { $0 }
        let uniqueDates = Array(Set(allDates)).filter { $0 >= today }.sorted()

        return uniqueDates.map { date in
            var row = DateRow(
                journeyId: referenceJourney.id,
                date: date,
                journey: referenceJourney
            )
            row.departureStationID = departureStationID
            row.arrivalStationID = arrivalStationID
            return row
        }
    }

    /// Resolves the company name from a VehicleJourney's first stop point ID.
    func resolveCompany(from journey: VehicleJourney) -> String? {
        guard let stopPointId = journey.stopTimes.first?.stopPoint.id else { return nil }
        let parts = stopPointId.components(separatedBy: " ")
        guard parts.count > 1 else { return nil }
        return parts[1].components(separatedBy: "-").first
    }
}
