//
//  PositionEstimator.swift
//  RailMapiOS
//
//  Estimates a train's current position by linearly interpolating between
//  the two scheduled stops surrounding `now`, optionally applying GTFS-RT delays.
//
//  Used as a fallback when GTFS-RT doesn't publish a vehicle position.
//

import CoreLocation
import Foundation

struct PositionEstimator: Sendable {

    struct Estimate: Equatable, Sendable {
        let coordinate: CLLocationCoordinate2D
        let bearing: Double
    }

    /// Estimates the current position of a journey based on stop times.
    /// Applies GTFS-RT delays with forward propagation (a delay at stop N
    /// carries over to stops N+1, N+2, … until a new explicit delay is announced —
    /// this is the standard GTFS-RT semantics).
    /// - Parameters:
    ///   - journey: persisted Journey with at least 2 stops with coordinates and times.
    ///   - now: reference time (use `Date()` in production, mockable for tests).
    ///   - stopUpdates: optional GTFS-RT delays applied per stop.
    /// - Returns: an `Estimate` or `nil` if the journey is outside its travel window.
    func estimate(journey: Journey, now: Date = Date(), stopUpdates: [StopTimeUpdateDTO] = []) -> Estimate? {
        guard let stops = journey.stops, stops.count >= 2 else { return nil }

        // 1. Sort stops by their *scheduled* time first (delays may not preserve order).
        let scheduled = stops.compactMap { stop -> (stop: Stop, baseTime: Date, coord: CLLocationCoordinate2D)? in
            guard let info = stop.stopinfo,
                  let lat = info.latitude, let lon = info.longitude else { return nil }
            let baseTime = stop.departureTimeUTC ?? stop.arrivalTimeUTC ?? .distantPast
            return (stop, baseTime, CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }
        .sorted { $0.baseTime < $1.baseTime }

        guard scheduled.count >= 2 else { return nil }

        // 2. Apply GTFS-RT delays with forward propagation.
        // A stop without an explicit delay inherits the previous one.
        var lastKnownDelay = 0
        let timed: [(stop: Stop, time: Date, coord: CLLocationCoordinate2D)] = scheduled.map { entry in
            if let stopID = entry.stop.stopinfo?.id,
               let update = stopUpdates.first(where: { $0.stopID == stopID }),
               let delay = update.departureDelay.map(Int.init) ?? update.arrivalDelay.map(Int.init) {
                lastKnownDelay = delay
            }
            let adjusted = entry.baseTime.addingTimeInterval(TimeInterval(lastKnownDelay))
            return (entry.stop, adjusted, entry.coord)
        }

        guard let first = timed.first, let last = timed.last else { return nil }

        // Before departure: train parked at origin. Bearing points along first segment
        // so the icon faces the right direction.
        if now < first.time {
            let bearing = BearingMath.bearing(from: first.coord, to: timed[1].coord)
            return Estimate(coordinate: first.coord, bearing: bearing)
        }
        // After arrival: nothing to estimate.
        if now > last.time { return nil }

        // In transit: find the segment [a, b] surrounding `now`.
        var a = timed[0]
        var b = timed[1]
        for i in 0..<(timed.count - 1) where timed[i].time <= now && now <= timed[i + 1].time {
            a = timed[i]
            b = timed[i + 1]
            break
        }

        let totalSeconds = b.time.timeIntervalSince(a.time)
        let elapsed = now.timeIntervalSince(a.time)
        let fraction = totalSeconds > 0 ? max(0, min(1, elapsed / totalSeconds)) : 0

        let lat = a.coord.latitude + fraction * (b.coord.latitude - a.coord.latitude)
        let lon = a.coord.longitude + fraction * (b.coord.longitude - a.coord.longitude)
        let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)

        let bearing = BearingMath.bearing(from: a.coord, to: b.coord)
        return Estimate(coordinate: coord, bearing: bearing)
    }
}
