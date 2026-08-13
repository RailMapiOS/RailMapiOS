//
//  MapRouteMatchingTests.swift
//  RailMapiOSTests
//
//  Regression guards for the August 2026 map bugs. Nothing used to tie a
//  `TrainRoute` back to the `Journey` it came from: routes got a fresh
//  `UUID()` on every regeneration, and the app re-derived the link from proxy
//  keys — origin/destination coordinates for selection, train number for live
//  markers — always taking the first match. Two saved trips sharing a route or
//  a train number (a recurring commute) then collided:
//
//   - tapping a trip highlighted a different one,
//   - both live markers pointed at the same polyline, so the other one never
//     split into travelled (grey) / remaining (colored) and looked frozen,
//   - resolved shapes were persisted onto the wrong journey.
//
//  Also covers `PositionEstimator` staying inside the leg the user travels.
//

import CoreLocation
import Foundation
import SwiftData
import Testing
// The app sources are compiled into this test target (see Project.swift),
// so the code under test is already in this module — no import needed.

@Suite("Map route ↔ journey matching", .tags(.map))
@MainActor
struct MapRouteMatchingTests {

    // Swift Testing builds a fresh instance per test, so this in-memory store
    // is created and torn down around each one — no shared state to reset.
    private let container: ModelContainer
    private let context: ModelContext

    // Coordinates are approximate — only their relative geometry matters here.
    private static let paris = CLLocationCoordinate2D(latitude: 48.8443, longitude: 2.3743)
    private static let lyon = CLLocationCoordinate2D(latitude: 45.7605, longitude: 4.8595)
    private static let valence = CLLocationCoordinate2D(latitude: 44.9911, longitude: 4.9769)

    init() throws {
        container = try ModelContainer(
            for: Journey.self, Stop.self, StopInfos.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = ModelContext(container)
    }

    // MARK: - Route identity

    @Test("A route's id is the id of the journey it came from")
    func routeIDIsTheJourneyID() throws {
        let journey = makeJourney(headsign: "6824", legs: [(Self.paris, "departure"), (Self.lyon, "arrival")])
        let routes = MapService().generateTrainRoutes(from: [journey])

        #expect(routes.count == 1)
        #expect(routes.first?.id == journey.id, "Route identity must come from the journey, not a fresh UUID().")
    }

    @Test("Regenerating routes keeps their ids, so the map selection survives")
    func routeIDsAreStableAcrossRegenerations() {
        let journeys = [
            makeJourney(headsign: "6824", legs: [(Self.paris, "departure"), (Self.lyon, "arrival")]),
            makeJourney(headsign: "6824", legs: [(Self.paris, "departure"), (Self.lyon, "arrival")])
        ]
        let service = MapService()

        #expect(service.generateTrainRoutes(from: journeys).map(\.id)
                == service.generateTrainRoutes(from: journeys).map(\.id))
    }

    // MARK: - Selection (tap a saved trip → highlight its route)

    @Test("Tapping a trip highlights its own route, not another trip on the same stations")
    func findMatchingRoutePicksTheTappedTrip() {
        // The exact shape of the prod bug: same train, same stations, two dates.
        let older = makeJourney(
            headsign: "8541",
            start: date("2026-08-06T13:47:00Z"),
            legs: [(Self.paris, "departure"), (Self.lyon, "arrival")]
        )
        let newer = makeJourney(
            headsign: "8541",
            start: date("2026-08-12T13:47:00Z"),
            legs: [(Self.paris, "departure"), (Self.lyon, "arrival")]
        )
        let service = MapService()
        // Sorted by startDate ascending, as `@Query(sort: \Journey.startDate)` delivers them.
        let routes = service.generateTrainRoutes(from: [older, newer])

        #expect(service.findMatchingRoute(for: newer, in: routes)?.id == newer.id,
                "Matching on endpoint coordinates alone returned the older trip.")
        #expect(service.findMatchingRoute(for: older, in: routes)?.id == older.id)
    }

    @Test("No route means no match")
    func findMatchingRouteReturnsNilWithoutRoutes() {
        let journey = makeJourney(headsign: "6824", legs: [(Self.paris, "departure"), (Self.lyon, "arrival")])
        #expect(MapService().findMatchingRoute(for: journey, in: []) == nil)
    }

    // MARK: - Live markers (travelled / remaining split)

    @Test("Two trips on the same train number get one route each")
    func markersGetTheirOwnRouteWhenSharingATrainNumber() throws {
        let now = Date()
        // Both in transit, same train number — the commuter case.
        let first = makeJourney(
            headsign: "6824",
            start: now.addingTimeInterval(-30 * 60),
            end: now.addingTimeInterval(90 * 60),
            legs: [(Self.paris, "departure"), (Self.lyon, "arrival")]
        )
        let second = makeJourney(
            headsign: "6824",
            start: now.addingTimeInterval(-20 * 60),
            end: now.addingTimeInterval(100 * 60),
            legs: [(Self.paris, "departure"), (Self.lyon, "arrival")]
        )
        let journeys = [first, second]
        let routes = MapService().generateTrainRoutes(from: journeys)

        let markers = AppFeature.buildVehicleMarkers(updates: [:], journeys: journeys, routes: routes)

        #expect(markers.count == 2)
        #expect(markers.first { $0.id == first.id }?.routeID == first.id)
        #expect(markers.first { $0.id == second.id }?.routeID == second.id)
        #expect(Set(markers.compactMap(\.routeID)).count == 2,
                "Both markers pointed at the same route, leaving the other polyline undivided.")
    }

    // MARK: - PositionEstimator confined to the travelled leg

    /// The train runs Paris → Lyon → Valence → Marseille; the user only rides
    /// Lyon → Valence. Before boarding, the marker belongs at Lyon — not out on
    /// the Paris–Lyon stretch, which the map doesn't even draw.
    @Test("Before boarding, the marker waits at the user's departure stop")
    func estimateBeforeBoardingSitsAtTheDepartureStop() throws {
        let estimate = try #require(
            PositionEstimator().estimate(journey: midRunJourney(), now: date("2026-08-12T09:30:00Z"))
        )

        expectCoordinate(estimate.coordinate, isCloseTo: Self.lyon)
    }

    @Test("Mid-leg, the marker interpolates between the user's own stops")
    func estimateMidLegInterpolatesWithinTheUsersLeg() throws {
        // Halfway through the 10:00 → 11:00 Lyon → Valence leg.
        let estimate = try #require(
            PositionEstimator().estimate(journey: midRunJourney(), now: date("2026-08-12T10:30:00Z"))
        )

        let midpoint = CLLocationCoordinate2D(
            latitude: (Self.lyon.latitude + Self.valence.latitude) / 2,
            longitude: (Self.lyon.longitude + Self.valence.longitude) / 2
        )
        expectCoordinate(estimate.coordinate, isCloseTo: midpoint)
    }

    @Test("Past the user's arrival there is nothing to estimate, even though the train runs on")
    func estimateStopsAtTheUsersArrival() {
        // 11:30 — past Valence, but the train is still heading to Marseille.
        #expect(PositionEstimator().estimate(journey: midRunJourney(), now: date("2026-08-12T11:30:00Z")) == nil,
                "Estimating over the whole run kept the marker alive past the user's arrival.")
    }

    @Test("A delay announced upstream of the boarding stop still propagates onto it")
    func estimateAppliesDelayAnnouncedBeforeBoarding() throws {
        // +30 min announced at Paris, upstream of the user's Lyon boarding stop.
        // GTFS-RT semantics propagate it forward, so at 10:20 the train has not
        // left Lyon yet and the marker stays there.
        let updates = [
            StopTimeUpdateDTO(
                stopID: "paris",
                stopSequence: 0,
                arrivalDelay: 1800,
                arrivalTime: nil,
                departureDelay: 1800,
                departureTime: nil,
                scheduleRelationship: 0,
                platform: nil
            )
        ]
        let estimate = try #require(
            PositionEstimator().estimate(
                journey: midRunJourney(),
                now: date("2026-08-12T10:20:00Z"),
                stopUpdates: updates
            )
        )

        expectCoordinate(estimate.coordinate, isCloseTo: Self.lyon)
    }

    // MARK: - Helpers

    private func expectCoordinate(
        _ actual: CLLocationCoordinate2D,
        isCloseTo expected: CLLocationCoordinate2D,
        tolerance: CLLocationDegrees = 0.0001,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        #expect(abs(actual.latitude - expected.latitude) < tolerance,
                "latitude \(actual.latitude) is not within \(tolerance) of \(expected.latitude)",
                sourceLocation: sourceLocation)
        #expect(abs(actual.longitude - expected.longitude) < tolerance,
                "longitude \(actual.longitude) is not within \(tolerance) of \(expected.longitude)",
                sourceLocation: sourceLocation)
    }

    // MARK: - Fixtures

    /// Paris → Lyon → Valence → Marseille, user boarding at Lyon and alighting
    /// at Valence (10:00 → 11:00 UTC).
    private func midRunJourney() -> Journey {
        let marseille = CLLocationCoordinate2D(latitude: 43.3025, longitude: 5.3806)
        return makeJourney(
            headsign: "6111",
            start: date("2026-08-12T10:00:00Z"),
            end: date("2026-08-12T11:00:00Z"),
            legs: [
                (Self.paris, ""),
                (Self.lyon, "departure"),
                (Self.valence, "arrival"),
                (marseille, "")
            ],
            stopTimes: [
                date("2026-08-12T08:00:00Z"),
                date("2026-08-12T10:00:00Z"),
                date("2026-08-12T11:00:00Z"),
                date("2026-08-12T12:00:00Z")
            ],
            stopIDs: ["paris", "lyon", "valence", "marseille"]
        )
    }

    /// Builds a persisted journey. `legs` pairs each stop with its status —
    /// only the user's boarding stop is `"departure"` and their alighting stop
    /// `"arrival"`; every other stop of the run carries an empty status, which
    /// is what `DateRow.toNewJourneyModel` produces.
    @discardableResult
    private func makeJourney(
        headsign: String,
        start: Date = Date(),
        end: Date? = nil,
        legs: [(CLLocationCoordinate2D, String)],
        stopTimes: [Date]? = nil,
        stopIDs: [String]? = nil
    ) -> Journey {
        let journey = Journey()
        journey.id = UUID()
        journey.headsign = headsign
        journey.company = "TGV INOUI"
        journey.idVehiculeJourney = "trip-\(headsign)-\(start.timeIntervalSince1970)"
        journey.startDate = start
        journey.endDate = end ?? start.addingTimeInterval(2 * 3600)
        journey.stops = []
        context.insert(journey)

        for (index, leg) in legs.enumerated() {
            let info = StopInfos()
            info.id = stopIDs?[index] ?? "stop-\(index)"
            info.label = info.id
            info.latitude = leg.0.latitude
            info.longitude = leg.0.longitude

            let stop = Stop()
            stop.status = leg.1
            let time = stopTimes?[index] ?? start.addingTimeInterval(TimeInterval(index) * 3600)
            stop.arrivalTimeUTC = time
            stop.departureTimeUTC = time
            stop.journey = journey
            stop.stopinfo = info
            info.stop = stop

            context.insert(info)
            context.insert(stop)
            journey.stops?.append(stop)
        }
        return journey
    }

    private func date(_ iso: String) -> Date {
        guard let date = ISO8601DateFormatter().date(from: iso) else {
            Issue.record("Bad fixture date: \(iso)")
            return Date()
        }
        return date
    }
}

extension Tag {
    @Tag static var map: Self
}
