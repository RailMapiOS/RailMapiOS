//
//  RealtimeStatus.swift
//  RailMapiOS
//
//  Per-journey aggregated real-time state (delay, platform, position, alerts).
//  Stored in AppFeature.State.realtimeUpdates keyed by Journey ID.
//

import CoreLocation
import Foundation

struct RealtimeStatus: Equatable, Sendable {
    /// Trip ID that the data was fetched for.
    let tripID: String

    /// Delay at the **departure** of the user's trip (seconds, signed).
    /// Positive = late, negative = early, nil = unknown.
    var departureDelaySeconds: Int?

    /// Delay at the **arrival** of the user's trip.
    var arrivalDelaySeconds: Int?

    /// Platform / quai assigned at the user's departure stop, when published.
    var departurePlatform: String?

    /// Whether the trip is canceled.
    var isCancelled: Bool = false

    /// Live vehicle position, if available.
    var vehicleCoordinate: CLLocationCoordinate2D?
    var vehicleBearing: Double?
    var vehicleSpeed: Double?

    /// Active alerts touching this trip.
    var alerts: [AlertDTO] = []

    /// All raw stop-time updates (for finer UI later).
    var stopUpdates: [StopTimeUpdateDTO] = []

    /// When this snapshot was last refreshed (used for staleness UI).
    var lastUpdated: Date

    static func == (lhs: RealtimeStatus, rhs: RealtimeStatus) -> Bool {
        lhs.tripID == rhs.tripID &&
        lhs.departureDelaySeconds == rhs.departureDelaySeconds &&
        lhs.arrivalDelaySeconds == rhs.arrivalDelaySeconds &&
        lhs.departurePlatform == rhs.departurePlatform &&
        lhs.isCancelled == rhs.isCancelled &&
        lhs.alerts == rhs.alerts &&
        lhs.stopUpdates == rhs.stopUpdates &&
        coordEqual(lhs.vehicleCoordinate, rhs.vehicleCoordinate)
    }

    private static func coordEqual(_ a: CLLocationCoordinate2D?, _ b: CLLocationCoordinate2D?) -> Bool {
        switch (a, b) {
        case (nil, nil): return true
        case (let x?, let y?): return x.latitude == y.latitude && x.longitude == y.longitude
        default: return false
        }
    }
}
