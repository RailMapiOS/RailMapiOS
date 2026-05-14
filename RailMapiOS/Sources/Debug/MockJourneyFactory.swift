//
//  MockJourneyFactory.swift
//  RailMapiOS
//
//  DEBUG-only journey templates exposing the main UI states the team needs
//  to verify quickly: tracking window edges, refund eligibility tiers, multi-
//  operator contacts, multi-stop itineraries, cancelled trips.
//
//  Each mock returns:
//    - a `NewJourneyModel` (saved through `DataControllerClient.saveJourney`)
//    - an optional `RealtimeStatus` keyed by `idVehicleJourney` (the GTFS-RT
//      `tripID`) so `JourneyDetailFeature.onAppear` can short-circuit the
//      real network call and use the mock state.
//

#if DEBUG
import Foundation

enum MockJourneyKind: String, CaseIterable, Identifiable {
    case activeOnTime
    case activeDelayed
    case upcomingWithinTracking
    case upcomingFar
    case pastOnTime
    case pastRefundEligible
    case multiStop
    case ouigo
    case intercites
    case cancelled

    var id: String { rawValue }

    /// Stable tripID stamped on the journey's `idVehicleJourney`. We persist
    /// this value in SwiftData so we can recover the matching `MockJourneyKind`
    /// after an app relaunch (when the in-memory mock cache is empty).
    var tripID: String {
        switch self {
        case .activeOnTime:           return "MOCK-active-ontime"
        case .activeDelayed:          return "MOCK-active-delayed"
        case .upcomingWithinTracking: return "MOCK-upcoming-tracked"
        case .upcomingFar:            return "MOCK-upcoming-far"
        case .pastOnTime:             return "MOCK-past-ontime"
        case .pastRefundEligible:     return "MOCK-past-refund"
        case .multiStop:              return "MOCK-multistop"
        case .ouigo:                  return "MOCK-ouigo"
        case .intercites:             return "MOCK-intercites"
        case .cancelled:              return "MOCK-cancelled"
        }
    }

    /// Reverse lookup — used to rebuild the realtime cache after relaunch.
    static func kind(forTripID tripID: String) -> MockJourneyKind? {
        allCases.first { $0.tripID == tripID }
    }

    /// Label shown in the debug menu.
    var label: String {
        switch self {
        case .activeOnTime:           return "Active TGV — on time"
        case .activeDelayed:          return "Active TGV — 45 min late (refund eligible)"
        case .upcomingWithinTracking: return "Upcoming — in 20 min (tracked)"
        case .upcomingFar:            return "Upcoming — in 2 days"
        case .pastOnTime:             return "Past — yesterday"
        case .pastRefundEligible:     return "Past — 1 h late (refund eligible)"
        case .multiStop:              return "Multi-stop TGV (Paris → Marseille)"
        case .ouigo:                  return "OUIGO"
        case .intercites:             return "Intercités"
        case .cancelled:              return "Cancelled trip"
        }
    }

    var systemImage: String {
        switch self {
        case .activeOnTime, .multiStop:        return "tram.fill"
        case .activeDelayed, .pastRefundEligible: return "exclamationmark.triangle.fill"
        case .upcomingWithinTracking:          return "clock.fill"
        case .upcomingFar:                     return "calendar"
        case .pastOnTime:                      return "checkmark.circle.fill"
        case .ouigo:                           return "bolt.car.fill"
        case .intercites:                      return "tram"
        case .cancelled:                       return "xmark.octagon.fill"
        }
    }
}

enum MockJourneyFactory {

    // MARK: - Public API

    /// Builds a mock journey + optional realtime snapshot for the given kind.
    static func make(_ kind: MockJourneyKind) -> (journey: NewJourneyModel, status: RealtimeStatus?) {
        switch kind {
        case .activeOnTime:           return activeOnTime()
        case .activeDelayed:          return activeDelayed()
        case .upcomingWithinTracking: return upcomingWithinTracking()
        case .upcomingFar:            return upcomingFar()
        case .pastOnTime:             return pastOnTime()
        case .pastRefundEligible:     return pastRefundEligible()
        case .multiStop:              return multiStop()
        case .ouigo:                  return ouigo()
        case .intercites:             return intercites()
        case .cancelled:              return cancelled()
        }
    }

    /// Returns a mock realtime status for the given trip ID, rebuilding the
    /// cache on demand. Survives app relaunches (the in-memory cache is
    /// regenerated lazily from the matching `MockJourneyKind`).
    static func realtimeStatus(forTripID tripID: String) -> RealtimeStatus? {
        if let cached = cachedStatuses[tripID] { return cached }
        // Cold lookup after a relaunch — rebuild from the kind matched by tripID.
        guard let kind = MockJourneyKind.kind(forTripID: tripID) else { return nil }
        _ = make(kind)
        return cachedStatuses[tripID]
    }

    // Cache populated on each `make()` call so subsequent lookups by tripID
    // return the same RealtimeStatus the journey was created with.
    private static var cachedStatuses: [String: RealtimeStatus] = [:]

    private static func remember(tripID: String, status: RealtimeStatus?) {
        guard let status else { return }
        cachedStatuses[tripID] = status
    }

    // MARK: - Builders

    private static func activeOnTime() -> (NewJourneyModel, RealtimeStatus?) {
        let now = Date()
        let start = now.addingTimeInterval(-30 * 60)        // started 30 min ago
        let end = now.addingTimeInterval(90 * 60)           // arrives in 1h30
        let trip = "MOCK-active-ontime"
        let journey = makeJourney(
            tripID: trip,
            company: "TGV INOUI",
            headsign: "6824",
            startDate: start,
            endDate: end,
            departure: parisGareDeLyon(at: start),
            arrival: lyonPartDieu(at: end)
        )
        let status = RealtimeStatus(
            tripID: trip,
            departureDelaySeconds: 0,
            arrivalDelaySeconds: 0,
            departurePlatform: "12",
            isCancelled: false,
            lastUpdated: now
        )
        remember(tripID: trip, status: status)
        return (journey, status)
    }

    private static func activeDelayed() -> (NewJourneyModel, RealtimeStatus?) {
        let now = Date()
        let start = now.addingTimeInterval(-60 * 60)
        let end = now.addingTimeInterval(40 * 60)
        let trip = "MOCK-active-delayed"
        let journey = makeJourney(
            tripID: trip,
            company: "TGV INOUI",
            headsign: "6839",
            startDate: start,
            endDate: end,
            departure: parisGareDeLyon(at: start),
            arrival: marseilleSaintCharles(at: end)
        )
        var status = RealtimeStatus(
            tripID: trip,
            departureDelaySeconds: 45 * 60,
            arrivalDelaySeconds: 45 * 60,
            departurePlatform: "9",
            isCancelled: false,
            lastUpdated: now
        )
        status.alerts = [makeAlert(
            id: "MOCK-alert-active-delayed",
            tripID: trip,
            header: "Train slowed by track work near Lyon",
            description: "Your train is running about 45 minutes late due to scheduled track work between Lyon and Avignon."
        )]
        remember(tripID: trip, status: status)
        return (journey, status)
    }

    private static func upcomingWithinTracking() -> (NewJourneyModel, RealtimeStatus?) {
        let now = Date()
        let start = now.addingTimeInterval(20 * 60)         // departs in 20 min
        let end = start.addingTimeInterval(120 * 60)
        let trip = "MOCK-upcoming-tracked"
        let journey = makeJourney(
            tripID: trip,
            company: "TGV INOUI",
            headsign: "8541",
            startDate: start,
            endDate: end,
            departure: parisGareDeLyon(at: start),
            arrival: bordeauxSaintJean(at: end)
        )
        let status = RealtimeStatus(
            tripID: trip,
            departureDelaySeconds: 0,
            arrivalDelaySeconds: 0,
            departurePlatform: "23",
            isCancelled: false,
            lastUpdated: now
        )
        remember(tripID: trip, status: status)
        return (journey, status)
    }

    private static func upcomingFar() -> (NewJourneyModel, RealtimeStatus?) {
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: 2, to: Date())!
        let end = start.addingTimeInterval(180 * 60)
        let trip = "MOCK-upcoming-far"
        let journey = makeJourney(
            tripID: trip,
            company: "TGV INOUI",
            headsign: "5172",
            startDate: start,
            endDate: end,
            departure: parisGareDeLyon(at: start),
            arrival: strasbourg(at: end)
        )
        // No RT status outside tracking window.
        return (journey, nil)
    }

    private static func pastOnTime() -> (NewJourneyModel, RealtimeStatus?) {
        let cal = Calendar.current
        let yesterday = cal.date(byAdding: .day, value: -1, to: Date())!
        let start = cal.date(bySettingHour: 14, minute: 0, second: 0, of: yesterday)!
        let end = start.addingTimeInterval(120 * 60)
        let trip = "MOCK-past-ontime"
        let journey = makeJourney(
            tripID: trip,
            company: "TGV INOUI",
            headsign: "6010",
            startDate: start,
            endDate: end,
            departure: lyonPartDieu(at: start),
            arrival: parisGareDeLyon(at: end)
        )
        return (journey, nil)
    }

    private static func pastRefundEligible() -> (NewJourneyModel, RealtimeStatus?) {
        let cal = Calendar.current
        let yesterday = cal.date(byAdding: .day, value: -1, to: Date())!
        let start = cal.date(bySettingHour: 9, minute: 30, second: 0, of: yesterday)!
        let end = start.addingTimeInterval(180 * 60)
        let trip = "MOCK-past-refund"
        let journey = makeJourney(
            tripID: trip,
            company: "TGV INOUI",
            headsign: "8527",
            startDate: start,
            endDate: end,
            departure: parisGareDeLyon(at: start),
            arrival: toulouseMatabiau(at: end)
        )
        var status = RealtimeStatus(
            tripID: trip,
            departureDelaySeconds: 60 * 60,
            arrivalDelaySeconds: 60 * 60,            // 1h late at arrival → 50% refund
            departurePlatform: "14",
            isCancelled: false,
            lastUpdated: yesterday
        )
        status.alerts = [makeAlert(
            id: "MOCK-alert-past-refund",
            tripID: trip,
            header: "Signalling failure between Bordeaux and Toulouse",
            description: "A signalling incident caused a 60-minute delay on this trip."
        )]
        remember(tripID: trip, status: status)
        return (journey, status)
    }

    private static func multiStop() -> (NewJourneyModel, RealtimeStatus?) {
        let now = Date()
        let start = now.addingTimeInterval(-30 * 60)
        let trip = "MOCK-multistop"
        var journey = makeJourney(
            tripID: trip,
            company: "TGV INOUI",
            headsign: "6111",
            startDate: start,
            endDate: start.addingTimeInterval(200 * 60),
            departure: parisGareDeLyon(at: start),
            arrival: marseilleSaintCharles(at: start.addingTimeInterval(200 * 60))
        )
        // Inject 2 intermediate stops between dep and arr.
        let lyon = lyonPartDieu(at: start.addingTimeInterval(120 * 60))
        let avignon = avignonTGV(at: start.addingTimeInterval(160 * 60))
        let intermediate1 = NewStop(
            arrivalTimeUTC: lyon.arrivalTimeUTC,
            departureTimeUTC: lyon.departureTimeUTC,
            status: "intermediate",
            stopInfo: lyon.stopInfo!
        )
        let intermediate2 = NewStop(
            arrivalTimeUTC: avignon.arrivalTimeUTC,
            departureTimeUTC: avignon.departureTimeUTC,
            status: "intermediate",
            stopInfo: avignon.stopInfo!
        )
        // Re-order: departure, intermediates, arrival.
        let dep = journey.stops.first { $0.status == "departure" }!
        let arr = journey.stops.first { $0.status == "arrival" }!
        journey.stops = [dep, intermediate1, intermediate2, arr]

        let status = RealtimeStatus(
            tripID: trip,
            departureDelaySeconds: 0,
            arrivalDelaySeconds: 0,
            departurePlatform: "20",
            isCancelled: false,
            lastUpdated: now
        )
        remember(tripID: trip, status: status)
        return (journey, status)
    }

    private static func ouigo() -> (NewJourneyModel, RealtimeStatus?) {
        let now = Date()
        let start = now.addingTimeInterval(60 * 60)
        let end = start.addingTimeInterval(180 * 60)
        let trip = "MOCK-ouigo"
        let journey = makeJourney(
            tripID: trip,
            company: "OUIGO",
            headsign: "7611",
            startDate: start,
            endDate: end,
            departure: parisGareDeLyon(at: start),
            arrival: lyonPartDieu(at: end)
        )
        return (journey, nil)
    }

    private static func intercites() -> (NewJourneyModel, RealtimeStatus?) {
        let now = Date()
        let start = now.addingTimeInterval(40 * 60)
        let end = start.addingTimeInterval(240 * 60)
        let trip = "MOCK-intercites"
        let journey = makeJourney(
            tripID: trip,
            company: "Intercités",
            headsign: "3711",
            startDate: start,
            endDate: end,
            departure: parisGareDeLyon(at: start),
            arrival: toulouseMatabiau(at: end)
        )
        return (journey, nil)
    }

    private static func cancelled() -> (NewJourneyModel, RealtimeStatus?) {
        let now = Date()
        let start = now.addingTimeInterval(60 * 60)
        let end = start.addingTimeInterval(120 * 60)
        let trip = "MOCK-cancelled"
        let journey = makeJourney(
            tripID: trip,
            company: "TGV INOUI",
            headsign: "6201",
            startDate: start,
            endDate: end,
            departure: parisGareDeLyon(at: start),
            arrival: lyonPartDieu(at: end)
        )
        var status = RealtimeStatus(
            tripID: trip,
            departureDelaySeconds: nil,
            arrivalDelaySeconds: nil,
            isCancelled: true,
            lastUpdated: now
        )
        status.alerts = [makeAlert(
            id: "MOCK-alert-cancelled",
            tripID: trip,
            header: "Trip cancelled — strike action",
            description: "This service has been cancelled. Please contact customer service or rebook on the next available train."
        )]
        remember(tripID: trip, status: status)
        return (journey, status)
    }

    /// Builds a synthetic `AlertDTO` scoped to the given trip ID.
    /// Mirrors the shape returned by `RealtimeService.fetchAlerts`.
    private static func makeAlert(id: String, tripID: String, header: String, description: String) -> AlertDTO {
        AlertDTO(
            alertID: id,
            cause: nil,
            effect: nil,
            url: nil,
            headerText: header,
            descriptionText: description,
            activePeriods: [],
            informedEntities: [
                EntityDTO(
                    agencyID: nil,
                    routeID: nil,
                    routeType: nil,
                    tripID: tripID,
                    stopID: nil,
                    directionID: nil
                )
            ]
        )
    }

    // MARK: - Generic builder

    private static func makeJourney(
        tripID: String,
        company: String,
        headsign: String,
        startDate: Date,
        endDate: Date,
        departure: NewStop,
        arrival: NewStop
    ) -> NewJourneyModel {
        NewJourneyModel(
            startDate: startDate,
            endDate: endDate,
            headsign: headsign,
            idVehicleJourney: tripID,
            company: company,
            stops: [departure, arrival]
        )
    }

    // MARK: - Station templates

    private static func parisGareDeLyon(at time: Date) -> NewStop {
        stop(
            id: "stop_area:SNCF:87686006",
            label: "Paris Gare de Lyon",
            lat: 48.8443,
            lon: 2.3744,
            status: "departure",
            time: time
        )
    }

    private static func lyonPartDieu(at time: Date) -> NewStop {
        stop(
            id: "stop_area:SNCF:87723197",
            label: "Lyon Part-Dieu",
            lat: 45.7605,
            lon: 4.8595,
            status: "arrival",
            time: time
        )
    }

    private static func marseilleSaintCharles(at time: Date) -> NewStop {
        stop(
            id: "stop_area:SNCF:87751008",
            label: "Marseille Saint-Charles",
            lat: 43.3027,
            lon: 5.3805,
            status: "arrival",
            time: time
        )
    }

    private static func bordeauxSaintJean(at time: Date) -> NewStop {
        stop(
            id: "stop_area:SNCF:87581009",
            label: "Bordeaux Saint-Jean",
            lat: 44.8259,
            lon: -0.5566,
            status: "arrival",
            time: time
        )
    }

    private static func strasbourg(at time: Date) -> NewStop {
        stop(
            id: "stop_area:SNCF:87212027",
            label: "Strasbourg",
            lat: 48.5849,
            lon: 7.7349,
            status: "arrival",
            time: time
        )
    }

    private static func toulouseMatabiau(at time: Date) -> NewStop {
        stop(
            id: "stop_area:SNCF:87611004",
            label: "Toulouse Matabiau",
            lat: 43.6112,
            lon: 1.4541,
            status: "arrival",
            time: time
        )
    }

    private static func avignonTGV(at time: Date) -> NewStop {
        stop(
            id: "stop_area:SNCF:87318964",
            label: "Avignon TGV",
            lat: 43.9213,
            lon: 4.7858,
            status: "intermediate",
            time: time
        )
    }

    private static func stop(id: String, label: String, lat: Double, lon: Double, status: String, time: Date) -> NewStop {
        NewStop(
            arrivalTimeUTC: time,
            departureTimeUTC: time,
            status: status,
            stopInfo: NewStopInfo(
                id: id,
                label: label,
                latitude: lat,
                longitude: lon,
                adress: "",
                pickUpAllowed: status != "arrival",
                dropOffAllowed: status != "departure",
                skippedStop: false
            )
        )
    }
}
#endif
