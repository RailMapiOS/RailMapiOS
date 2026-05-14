//
//  SearchResultsService.swift
//  RailMapiOS
//
//  Groups raw VehicleJourney results into deduplicated SearchResults.
//  Two journeys with same origin, destination, departure & arrival times are
//  considered the same trip (just with different operating calendars).
//

import Foundation

struct SearchResultsService: Sendable {
    private let vehicleJourneyService: VehicleJourneyService

    init(vehicleJourneyService: VehicleJourneyService = VehicleJourneyService()) {
        self.vehicleJourneyService = vehicleJourneyService
    }

    /// Groups raw API results into unique trips, sorted by next departure date.
    /// Two journeys sharing the same headsign + operator are considered the same train,
    /// even if some have shorter routes (skipped stops) or different calendars.
    /// The representative is the trip with the most stops (the most complete route).
    func groupResults(_ journeys: [VehicleJourney]) -> [SearchResult] {
        let grouped = Dictionary(grouping: journeys) { Self.groupKey(for: $0) }
        let passageDays = vehicleJourneyService.passageDays(from: journeys)
        let today = Calendar.current.startOfDay(for: Date())

        return grouped.compactMap { key, trips -> SearchResult? in
            // Pick the trip with the most stops as the canonical "full route" representation
            let representative = trips.max(by: { $0.stopTimes.count < $1.stopTimes.count }) ?? trips.first
            guard let representative else { return nil }

            // Merge passage days across all calendars
            let allDates = trips.flatMap { passageDays[$0.id] ?? [] }
            let nextDeparture = allDates.filter { $0 >= today }.min()

            return SearchResult(
                id: key,
                representative: representative,
                trips: trips,
                nextDeparture: nextDeparture
            )
        }
        .sorted { lhs, rhs in
            switch (lhs.nextDeparture, rhs.nextDeparture) {
            case (nil, nil): return lhs.originTime < rhs.originTime
            case (nil, _): return false
            case (_, nil): return true
            case (let a?, let b?): return a < b
            }
        }
    }

    // MARK: - Group key

    /// A train is uniquely identified by `headsign + operator`.
    /// All trips that share these are merged: same number, same operator = same train.
    /// Different calendars / shorter sub-routes are considered variants of the same train.
    private static func groupKey(for journey: VehicleJourney) -> String {
        let operatorCode = operatorPrefix(from: journey)
        return "\(operatorCode)|\(journey.headsign)"
    }

    /// Extracts the operator prefix from the first stop's stop point ID
    /// (matching JourneyFilterService.resolveCompany logic).
    private static func operatorPrefix(from journey: VehicleJourney) -> String {
        guard let stopID = journey.stopTimes.first?.stopPoint.id else { return "?" }
        let parts = stopID.components(separatedBy: " ")
        if parts.count > 1, let prefix = parts[1].components(separatedBy: "-").first {
            return prefix
        }
        return stopID
    }
}
