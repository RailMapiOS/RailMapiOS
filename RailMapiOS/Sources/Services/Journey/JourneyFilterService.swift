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
    /// The reference journey carried in each row is the one that actually contains
    /// the selected stations (otherwise downstream UI resolves them to nil).
    func buildDateRows(
        from vehicleJourneys: [VehicleJourney],
        departureStationID: String?,
        arrivalStationID: String?
    ) -> [DateRow] {
        guard let referenceJourney = pickReferenceJourney(
            from: vehicleJourneys,
            departureStationID: departureStationID,
            arrivalStationID: arrivalStationID
        ) else { return [] }

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

    /// Picks the journey that contains both station IDs, preferring the one with the
    /// most stops (matches the `representative` used in StationPicker). Falls back to
    /// the longest journey if no exact match (shouldn't happen if user picked from it).
    private func pickReferenceJourney(
        from journeys: [VehicleJourney],
        departureStationID: String?,
        arrivalStationID: String?
    ) -> VehicleJourney? {
        let containingBoth = journeys.filter { journey in
            let ids = Set(journey.stopTimes.map(\.stopPoint.id))
            let depOK = departureStationID.map(ids.contains) ?? true
            let arrOK = arrivalStationID.map(ids.contains) ?? true
            return depOK && arrOK
        }
        return containingBoth.max(by: { $0.stopTimes.count < $1.stopTimes.count })
            ?? journeys.max(by: { $0.stopTimes.count < $1.stopTimes.count })
    }

    /// Resolves the company name from a VehicleJourney's first stop point ID.
    func resolveCompany(from journey: VehicleJourney) -> String? {
        guard let stopPointId = journey.stopTimes.first?.stopPoint.id else { return nil }
        let parts = stopPointId.components(separatedBy: " ")
        guard parts.count > 1 else { return nil }
        return parts[1].components(separatedBy: "-").first
    }
}
