//
//  JourneyFilterClient.swift
//  RailMapiOS
//
//  TCA Dependency for journey filtering and date row building logic.
//  Extracts business logic previously embedded in BottomSheetViewModel.
//

import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct JourneyFilterClient {
    /// Filters saved journeys by search text (headsign matching).
    var filterJourneys: @Sendable (_ allJourneys: [Journey], _ searchText: String) -> [Journey] = { journeys, _ in journeys }

    /// Builds DateRows from multiple VehicleJourneys, merging all passage days.
    /// Carries over station selections and filters out past dates.
    var buildDateRows: @Sendable (
        _ vehicleJourneys: [VehicleJourney],
        _ departureStationID: String?,
        _ arrivalStationID: String?
    ) -> [DateRow] = { _, _, _ in [] }

    /// Resolves the company name from a VehicleJourney's stop point ID.
    var resolveCompany: @Sendable (_ journey: VehicleJourney) -> String? = { _ in nil }
}

extension JourneyFilterClient: DependencyKey {
    static let liveValue: Self = {
        let vehicleJourneyService = VehicleJourneyService()

        return Self(
            filterJourneys: { allJourneys, searchText in
                guard !searchText.isEmpty else { return allJourneys }
                return allJourneys.filter { journey in
                    guard let headsign = journey.headsign else { return false }
                    return headsign.localizedCaseInsensitiveContains(searchText)
                }
            },
            buildDateRows: { vehicleJourneys, departureStationID, arrivalStationID in
                let passageDays = vehicleJourneyService.getPassageDays(from: vehicleJourneys)
                let today = Calendar.current.startOfDay(for: Date())

                var allDates: [Date] = []
                for (_, dates) in passageDays {
                    allDates.append(contentsOf: dates)
                }

                let uniqueDates = Array(Set(allDates)).filter { $0 >= today }.sorted()
                let referenceJourney = vehicleJourneys.first!

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
            },
            resolveCompany: { journey in
                guard let stopPointId = journey.stopTimes.first?.stopPoint.id else { return nil }
                let parts = stopPointId.components(separatedBy: " ")
                guard parts.count > 1,
                      let company = parts[1].components(separatedBy: "-").first else { return nil }
                return company
            }
        )
    }()
}

extension DependencyValues {
    var journeyFilterClient: JourneyFilterClient {
        get { self[JourneyFilterClient.self] }
        set { self[JourneyFilterClient.self] = newValue }
    }
}
