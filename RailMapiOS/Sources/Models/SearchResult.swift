//
//  SearchResult.swift
//  RailMapiOS
//
//  A grouped search result: one row per unique trip (origin/destination/times),
//  bundling all VehicleJourneys that share the same shape but have different calendars.
//

import Foundation

struct SearchResult: Identifiable, Hashable {
    /// Stable ID = origin + destination + departureTime + arrivalTime hash.
    let id: String
    /// The representative VehicleJourney (used for station picker).
    let representative: VehicleJourney
    /// All trips backing this result (for merging passage days across calendars).
    let trips: [VehicleJourney]
    /// Next operating date across all trips (for sorting + UI hint).
    let nextDeparture: Date?

    var headsign: String { representative.headsign }
    var originName: String { representative.stopTimes.first?.stopPoint.name ?? "—" }
    var destinationName: String { representative.stopTimes.last?.stopPoint.name ?? "—" }
    var originTime: String { representative.stopTimes.first?.departureTime ?? "" }
    var destinationTime: String { representative.stopTimes.last?.arrivalTime ?? "" }
    var stopCount: Int { representative.stopTimes.count }

    static func == (lhs: SearchResult, rhs: SearchResult) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
