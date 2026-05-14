//
//  AppFeature.swift
//  RailMapiOS
//

import ComposableArchitecture
import CoreLocation
import Foundation
import SwiftUI

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var map = MapFeature.State()
        var bottomSheet = BottomSheetFeature.State()
        var isSheetPresented = true
        var sheetSize: PresentationDetent = .fraction(0.3)

        /// Live GTFS-RT status keyed by Journey.id.
        /// Populated by the polling loop, consumed by future UI overlays.
        var realtimeUpdates: [UUID: RealtimeStatus] = [:]

        /// Cooldown tracker: last time we asked the geometry client to refetch a
        /// route's shape with a GPS waypoint inserted. Prevents API spam when a
        /// train is genuinely off the precomputed shape (e.g. detour).
        var lastWaypointRefetch: [UUID: Date] = [:]

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.map == rhs.map &&
            lhs.bottomSheet == rhs.bottomSheet &&
            lhs.isSheetPresented == rhs.isSheetPresented &&
            lhs.sheetSize == rhs.sheetSize &&
            lhs.realtimeUpdates == rhs.realtimeUpdates &&
            lhs.lastWaypointRefetch == rhs.lastWaypointRefetch
        }
    }

    enum Action {
        case map(MapFeature.Action)
        case bottomSheet(BottomSheetFeature.Action)
        case journeysLoaded([Journey])
        case sheetSizeChanged(PresentationDetent)

        // MARK: - Realtime tracking
        case startRealtimeTracking
        case realtimePollTick
        case markersTick
        case realtimeUpdateReceived(journeyID: UUID, status: RealtimeStatus)
    }

    @Dependency(\.mapClient) var mapClient
    @Dependency(\.realtimeClient) var realtimeClient
    @Dependency(\.continuousClock) var clock

    /// Polling interval for GTFS-RT API fetches (per-journey trip updates + position + alerts).
    private static let pollInterval: Duration = .seconds(30)
    /// Faster cadence for re-interpolating estimated positions between RT polls.
    /// 1Hz is plenty visually and the math (linear interp + one orthogonal snap
    /// per train) is sub-millisecond — Core Animation fills the gaps for free.
    static let markersTickInterval: Duration = .seconds(1)

    private enum CancelID: Hashable {
        case realtimeTimer
        case markersTimer
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.map, action: \.map) { MapFeature() }
        Scope(state: \.bottomSheet, action: \.bottomSheet) { BottomSheetFeature() }

        Reduce { state, action in
            switch action {
            // MARK: - Journeys sync (SwiftData → Map + BottomSheet)

            case .journeysLoaded(let journeys):
                return .merge(
                    .send(.map(.journeysUpdated(journeys))),
                    .send(.bottomSheet(.journeysUpdated(journeys))),
                    .send(.startRealtimeTracking),
                    // Trigger an immediate poll so we don't wait 30s on first launch.
                    .send(.realtimePollTick)
                )

            // MARK: - Sheet size sync

            case .sheetSizeChanged(let size):
                state.sheetSize = size
                return .send(.bottomSheet(.sheetSizeChanged(size)))

            case .bottomSheet(.sheetSizeChanged(let size)):
                state.sheetSize = size
                return .none

            // MARK: - Journey selection → Map route selection

            case .bottomSheet(.journeyTapped(let journey)):
                if let matchingRoute = mapClient.findMatchingRoute(journey, state.map.trainRoutes) {
                    return .send(.map(.selectRoute(matchingRoute)))
                }
                return .none

            // MARK: - Clear route selection on nav back (popFrom or pop via swipe)

            case .bottomSheet(.path(.popFrom)):
                return .send(.map(.clearRouteSelection))

            // MARK: - Realtime tracking

            case .startRealtimeTracking:
                return .merge(
                    // 30s — fetch live GTFS-RT
                    .run { send in
                        for await _ in clock.timer(interval: Self.pollInterval) {
                            await send(.realtimePollTick)
                        }
                    }
                    .cancellable(id: CancelID.realtimeTimer, cancelInFlight: true),

                    // 5s — re-interpolate estimated positions for smooth UI
                    .run { send in
                        for await _ in clock.timer(interval: Self.markersTickInterval) {
                            await send(.markersTick)
                        }
                    }
                    .cancellable(id: CancelID.markersTimer, cancelInFlight: true)
                )

            case .realtimePollTick:
                // Refresh markers immediately (estimated positions advance even without RT data)
                let immediateMarkers = Self.buildVehicleMarkers(
                    updates: state.realtimeUpdates,
                    journeys: state.bottomSheet.allJourneys,
                    routes: state.map.trainRoutes
                )
                let active = state.bottomSheet.allJourneys.filter { $0.isActiveForTracking }
                let fetches = active.compactMap { fetchEffect(for: $0) }
                return .merge([.send(.map(.vehicleMarkersUpdated(immediateMarkers)))] + fetches)

            case .markersTick:
                let markers = Self.buildVehicleMarkers(
                    updates: state.realtimeUpdates,
                    journeys: state.bottomSheet.allJourneys,
                    routes: state.map.trainRoutes
                )
                return .send(.map(.vehicleMarkersUpdated(markers)))

            case .realtimeUpdateReceived(let id, let status):
                state.realtimeUpdates[id] = status
                // Mirror into the bottom sheet so the saved-journey list can
                // surface refund-eligible rows in their own priority section.
                state.bottomSheet.realtimeUpdates[id] = status
                let markers = Self.buildVehicleMarkers(
                    updates: state.realtimeUpdates,
                    journeys: state.bottomSheet.allJourneys,
                    routes: state.map.trainRoutes
                )

                // Detect off-shape GPS positions and trigger a corrected refetch
                // (with a 5-min per-route cooldown to avoid hammering the API).
                let drifts = Self.detectShapeDrifts(
                    updates: state.realtimeUpdates,
                    journeys: state.bottomSheet.allJourneys,
                    routes: state.map.trainRoutes
                )
                let now = Date()
                let cooldown: TimeInterval = 300
                var refetchEffects: [Effect<Action>] = []
                for drift in drifts {
                    if let last = state.lastWaypointRefetch[drift.routeID],
                       now.timeIntervalSince(last) < cooldown { continue }
                    state.lastWaypointRefetch[drift.routeID] = now
                    refetchEffects.append(.send(.map(.refetchShapeWithWaypoint(
                        routeID: drift.routeID,
                        waypoint: drift.waypoint,
                        stopInsertionIndex: drift.stopInsertionIndex
                    ))))
                }

                return .merge([.send(.map(.vehicleMarkersUpdated(markers)))] + refetchEffects)

            // MARK: - Passthrough

            case .map, .bottomSheet:
                return .none
            }
        }
    }

    // MARK: - Realtime fetch effect

    /// Builds an effect that fetches all real-time data for a single journey.
    /// Returns nil when the journey lacks the IDs required to query the API.
    private func fetchEffect(for journey: Journey) -> Effect<Action>? {
        guard let journeyID = journey.id, let tripID = journey.idVehiculeJourney else { return nil }
        let source = Self.apiSource(for: journey)
        let depStopID = journey.stops?.first(where: { $0.status?.lowercased() == "departure" })?.stopinfo?.id
        let arrStopID = journey.stops?.first(where: { $0.status?.lowercased() == "arrival" })?.stopinfo?.id

        return .run { send in
            // Fetch concurrently. Failures fall through silently (we keep last known state).
            async let tripUpdate = try? await realtimeClient.fetchTripUpdate(tripID, source)
            async let vehiclePosition = try? await realtimeClient.fetchVehiclePosition(tripID, source)
            async let alerts = (try? await realtimeClient.fetchAlerts(source, tripID)) ?? []

            let (update, position, alertsList) = await (tripUpdate, vehiclePosition, alerts)

            let status = Self.buildStatus(
                tripID: tripID,
                tripUpdate: update ?? nil,
                vehiclePosition: position ?? nil,
                alerts: alertsList,
                departureStopID: depStopID,
                arrivalStopID: arrStopID
            )

            await send(.realtimeUpdateReceived(journeyID: journeyID, status: status))
        }
    }

    // MARK: - Source mapping

    /// Maps a saved Journey's company to the corresponding API `?source=` identifier.
    /// Falls back to `sncf-ter` (the dominant operator in the dataset).
    static func apiSource(for journey: Journey) -> String {
        guard let raw = journey.company?.uppercased() else { return "sncf-ter" }
        switch raw {
        case let s where s.contains("TGV") || s.contains("INOUI"): return "sncf-tgv"
        case let s where s.contains("INTERCITES") || s.contains("INTERCITÉS"): return "sncf-intercites"
        case let s where s.contains("OUIGO"): return "ouigo"
        case let s where s.contains("EUROSTAR"): return "eurostar"
        case let s where s.contains("DB") || s.contains("DEUTSCHE"): return "db"
        case let s where s.contains("SBB") || s.contains("CFF"): return "sbb"
        case let s where s.contains("RENFE"): return "renfe"
        case let s where s.contains("SNCB") || s.contains("NMBS"): return "sncb"
        case let s where s.contains("TRENITALIA"): return "trenitalia-france"
        default: return "sncf-ter"
        }
    }

    // MARK: - Vehicle markers

    /// Above this distance (meters) a real GPS position is considered "off shape" —
    /// the rendered polyline is wrong and we trigger a refetch with the live coord
    /// inserted as an intermediate waypoint.
    static let shapeDriftThresholdMeters: Double = 200

    /// Drift event: a real GPS coord that doesn't sit on the route polyline.
    struct ShapeDrift: Equatable, Sendable {
        let routeID: UUID
        let waypoint: CLLocationCoordinate2D
        /// Index in `route.stopCoordinates` after which the waypoint should be inserted.
        let stopInsertionIndex: Int

        static func == (lhs: ShapeDrift, rhs: ShapeDrift) -> Bool {
            lhs.routeID == rhs.routeID &&
            lhs.waypoint.latitude == rhs.waypoint.latitude &&
            lhs.waypoint.longitude == rhs.waypoint.longitude &&
            lhs.stopInsertionIndex == rhs.stopInsertionIndex
        }
    }

    /// Builds the live train markers for every journey currently in its travel window.
    /// Priority for position:
    ///   1. GTFS-RT vehicle position (from `RealtimeStatus.vehicleCoordinate`) — kept as-is.
    ///   2. Linear interpolation between scheduled stops (with GTFS-RT delays applied),
    ///      then snapped to the route polyline so the icon stays on the rails.
    /// Bearing falls back from GTFS-RT → route polyline tangent → segment AB.
    static func buildVehicleMarkers(
        updates: [UUID: RealtimeStatus],
        journeys: [Journey],
        routes: [TrainRoute]
    ) -> [VehicleMarker] {
        let estimator = PositionEstimator()
        let now = Date()

        return journeys
            .filter { $0.isActiveForTracking }
            .compactMap { journey -> VehicleMarker? in
                guard let journeyID = journey.id else { return nil }
                let status = updates[journeyID]
                let route = routes.first { $0.headsign == journey.headsign }
                let polyline = route?.routeCoordinates ?? []

                // 1. Real GPS position from GTFS-RT — never snap, this is ground truth.
                if let coord = status?.vehicleCoordinate {
                    let bearing = status?.vehicleBearing
                        ?? BearingMath.bearingAlongRoute(near: coord, route: polyline)
                    return VehicleMarker(
                        id: journeyID,
                        coordinate: coord,
                        bearing: bearing,
                        company: journey.company,
                        routeID: route?.id
                    )
                }

                // 2. Estimated position — snap onto the polyline so the train follows the rails.
                if let estimate = estimator.estimate(
                    journey: journey,
                    now: now,
                    stopUpdates: status?.stopUpdates ?? []
                ) {
                    if let snap = BearingMath.snap(point: estimate.coordinate, to: polyline) {
                        return VehicleMarker(
                            id: journeyID,
                            coordinate: snap.point,
                            bearing: snap.bearing,
                            company: journey.company,
                            routeID: route?.id
                        )
                    }
                    return VehicleMarker(
                        id: journeyID,
                        coordinate: estimate.coordinate,
                        bearing: estimate.bearing,
                        company: journey.company,
                        routeID: route?.id
                    )
                }

                return nil
            }
    }

    /// Detects real GPS positions that are off the rendered shape by more than
    /// `shapeDriftThresholdMeters`. Each drift describes where to insert the GPS
    /// point as a waypoint in the journey's stop list to refetch a corrected shape.
    static func detectShapeDrifts(
        updates: [UUID: RealtimeStatus],
        journeys: [Journey],
        routes: [TrainRoute]
    ) -> [ShapeDrift] {
        journeys
            .filter { $0.isActiveForTracking }
            .compactMap { journey -> ShapeDrift? in
                guard let journeyID = journey.id,
                      let coord = updates[journeyID]?.vehicleCoordinate,
                      let route = routes.first(where: { $0.headsign == journey.headsign })
                else { return nil }

                // Drift = distance from GPS to the (smooth) polyline.
                guard let polylineSnap = BearingMath.snap(point: coord, to: route.routeCoordinates),
                      polylineSnap.distanceMeters > shapeDriftThresholdMeters
                else { return nil }

                // Insertion point = closest stop-segment in the journey's stop list.
                guard let stopSnap = BearingMath.snap(point: coord, to: route.stopCoordinates)
                else { return nil }

                return ShapeDrift(
                    routeID: route.id,
                    waypoint: coord,
                    stopInsertionIndex: stopSnap.segmentIndex
                )
            }
    }

    // MARK: - Status aggregation

    /// Looks up the StopTimeUpdate matching a given parent stop ID. Tolerates
    /// the SNCF pattern of redirecting `stop_id` to a child stop suffixed
    /// with the platform_code (e.g. parent `87611004` → child `87611004-3`).
    /// First tries exact match, then prefix match on `<parent>-` / `<parent>:`.
    static func matchingStopUpdate(
        in updates: [StopTimeUpdateDTO],
        parentID: String
    ) -> StopTimeUpdateDTO? {
        if let exact = updates.first(where: { $0.stopID == parentID }) {
            return exact
        }
        return updates.first { update in
            update.stopID.hasPrefix("\(parentID)-") || update.stopID.hasPrefix("\(parentID):")
        }
    }

    /// Folds raw GTFS-RT data into a single `RealtimeStatus` for the journey.
    static func buildStatus(
        tripID: String,
        tripUpdate: TripUpdateDTO?,
        vehiclePosition: VehiclePositionDTO?,
        alerts: [AlertDTO],
        departureStopID: String?,
        arrivalStopID: String?
    ) -> RealtimeStatus {
        var status = RealtimeStatus(tripID: tripID, lastUpdated: Date())

        if let tripUpdate {
            status.isCancelled = tripUpdate.isCancelled
            status.stopUpdates = tripUpdate.stopTimeUpdates

            // Stop matching tolerates child-stop redirection: SNCF often
            // changes the published stop_id from the parent `stop_area`
            // (e.g. "87611004") to a child carrying `platform_code`
            // (e.g. "87611004-3"). We accept exact and prefix matches.
            if let depID = departureStopID,
               let depUpdate = matchingStopUpdate(in: tripUpdate.stopTimeUpdates, parentID: depID) {
                status.departureDelaySeconds = depUpdate.departureDelay.map(Int.init)
                    ?? depUpdate.arrivalDelay.map(Int.init)
                // Platform now resolved server-side from the static feed.
                status.departurePlatform = depUpdate.platform
            }
            if let arrID = arrivalStopID,
               let arrUpdate = matchingStopUpdate(in: tripUpdate.stopTimeUpdates, parentID: arrID) {
                status.arrivalDelaySeconds = arrUpdate.arrivalDelay.map(Int.init)
                    ?? arrUpdate.departureDelay.map(Int.init)
            }
        }

        if let pos = vehiclePosition,
           let lat = pos.latitude, let lon = pos.longitude {
            status.vehicleCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            status.vehicleBearing = pos.bearing.map(Double.init)
            status.vehicleSpeed = pos.speed.map(Double.init)
        }

        status.alerts = alerts
        return status
    }
}
