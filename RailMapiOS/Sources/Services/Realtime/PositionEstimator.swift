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

    /// A stop with its delay-adjusted time and coordinate.
    private typealias TimedStop = (stop: Stop, time: Date, coord: CLLocationCoordinate2D)

    /// Estimates the current position of a journey based on stop times.
    /// Applies GTFS-RT delays with forward propagation (a delay at stop N
    /// carries over to stops N+1, N+2, … until a new explicit delay is announced —
    /// this is the standard GTFS-RT semantics).
    ///
    /// The estimate is confined to the leg the user actually travels (their
    /// boarding stop → their alighting stop). `journey.stops` holds the train's
    /// whole run, which is usually longer at one or both ends, and the rendered
    /// polyline only covers the user's leg: interpolating over the full run put
    /// the marker outside the polyline, where snapping pinned it to an endpoint
    /// and it sat there, apparently frozen.
    ///
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
        // A stop without an explicit delay inherits the previous one. Run this
        // over the *whole* trip, before narrowing to the user's leg: a delay
        // announced upstream of their boarding stop still propagates onto it.
        var lastKnownDelay = 0
        let wholeRun: [TimedStop] = scheduled.map { entry in
            if let stopID = entry.stop.stopinfo?.id,
               let update = stopUpdates.first(where: { $0.stopID == stopID }),
               let delay = update.departureDelay.map(Int.init) ?? update.arrivalDelay.map(Int.init) {
                lastKnownDelay = delay
            }
            let adjusted = entry.baseTime.addingTimeInterval(TimeInterval(lastKnownDelay))
            return (entry.stop, adjusted, entry.coord)
        }

        // 3. Narrow to the user's leg, so the estimate spans exactly what the
        // map draws. Same slicing as `MapService.generateTrainRoutes`.
        let timed = Self.travelledLeg(of: wholeRun)
        guard timed.count >= 2, let first = timed.first, let last = timed.last else { return nil }

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

    /// The slice of the run between the stop the user boards at (`departure`)
    /// and the one they get off at (`arrival`). Every other stop carries an
    /// empty status — see `DateRow.toNewJourneyModel`.
    ///
    /// Falls back to the whole run when the markers are missing or inverted, so
    /// a malformed journey still yields a position rather than none.
    private static func travelledLeg(of run: [TimedStop]) -> [TimedStop] {
        guard let depIdx = run.firstIndex(where: { $0.stop.status?.lowercased() == "departure" }),
              let arrIdx = run.lastIndex(where: { $0.stop.status?.lowercased() == "arrival" }),
              depIdx < arrIdx
        else { return run }
        return Array(run[depIdx...arrIdx])
    }
}
