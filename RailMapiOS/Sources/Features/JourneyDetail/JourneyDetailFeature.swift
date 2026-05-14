//
//  JourneyDetailFeature.swift
//  RailMapiOS
//

import ComposableArchitecture
import Foundation

@Reducer
struct JourneyDetailFeature {
    @ObservableState
    struct State: Equatable {
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.journey.id == rhs.journey.id &&
            lhs.realtimeStatus == rhs.realtimeStatus &&
            lhs.refundFlow == rhs.refundFlow
        }

        var journey: Journey

        /// Latest GTFS-RT snapshot for this journey. Fetched once on appear,
        /// kept in feature state so the eligibility banner updates as the
        /// user opens the screen.
        var realtimeStatus: RealtimeStatus?

        /// Modal claim flow state (sheet/full-screen cover). Non-nil when the
        /// user has tapped the refund banner.
        @Presents var refundFlow: RefundFlowFeature.State?

        var departureLabel: String {
            guard let stops = journey.stops,
                  let departureStop = stops.first(where: { $0.status == "departure" }) else { return "N/A" }
            return departureStop.stopinfo?.label ?? "N/A"
        }

        var arrivalLabel: String {
            guard let stops = journey.stops,
                  let arrivalStop = stops.first(where: { $0.status == "arrival" }) else { return "N/A" }
            return arrivalStop.stopinfo?.label ?? "N/A"
        }

        var stopsCount: Int {
            journey.stops?.count ?? 0
        }

        // MARK: - Refund eligibility (derived)

        /// Rules for this journey's operator (SNCF G30, OUIGO, …).
        var claimRules: (any ClaimRules)? {
            ClaimRegistry.rules(for: journey.company)
        }

        /// Operator contact card surfaced at the bottom of the detail screen.
        /// Always available for every operator we have rules for, regardless
        /// of delay / eligibility.
        var operatorContact: OperatorContact? { claimRules?.contact }

        /// Live delay / cancellation / disruption banner content, derived
        /// from the realtime feed. Nil only when nothing is reported.
        /// Resolution priority:
        ///   1. Cancellation (red)
        ///   2. Measured delay ≥ 1 min (orange + delay duration)
        ///   3. Active alert affecting the trip / route / stop (orange,
        ///      no specific delay shown — the alert text speaks for itself)
        var delayInfo: DelayInfo? {
            guard let status = realtimeStatus else { return nil }
            let firstAlert = status.alerts
                .compactMap { ($0.headerText?.isEmpty == false) ? $0.headerText : $0.descriptionText }
                .first

            if status.isCancelled {
                return DelayInfo(kind: .cancelled, alertMessage: firstAlert)
            }
            if let secs = status.arrivalDelaySeconds, secs >= 60 {
                return DelayInfo(kind: .delayed(minutes: secs / 60), alertMessage: firstAlert)
            }
            // No measured delay but the operator published a disruption alert
            // → still surface it. Common case for SNCF TER where trip-update
            // 404s but `/realtime/alerts` returns line-wide perturbations.
            if let firstAlert {
                return DelayInfo(kind: .disrupted, alertMessage: firstAlert)
            }
            return nil
        }

        /// Computed eligibility for the user's arrival delay (the moment that
        /// matters legally). Returns nil if no realtime data, if delay is
        /// below the operator's threshold, or if the user previously
        /// dismissed the banner via swipe.
        var claimEligibility: ClaimEligibility? {
            guard journey.refundBannerDismissed != true else { return nil }
            guard let rules = claimRules,
                  let delaySeconds = realtimeStatus?.arrivalDelaySeconds
            else { return nil }
            return rules.evaluate(delayMinutes: max(0, delaySeconds / 60))
        }

        /// Pre-built payload passed to the refund WebView so the chips have
        /// every field the user needs to copy-paste.
        var refundFlowState: RefundFlowFeature.State? {
            guard let contact = operatorContact,
                  let url = contact.refundFormURL
            else { return nil }
            return RefundFlowFeature.State(
                claimURL: url,
                operatorName: contact.displayName,
                requiresLogin: contact.refundFormRequiresLogin,
                bookingReference: nil,  // user enters once via journey detail later
                trainNumber: journey.headsign ?? "",
                journeyDate: journey.startDate ?? Date(),
                departureLabel: departureLabel,
                arrivalLabel: arrivalLabel,
                delayMinutes: claimEligibility?.delayMinutes ?? 0
            )
        }
    }

    enum Action {
        case onAppear
        case onDisappear
        case realtimeStatusFetched(RealtimeStatus?)
        case refundBannerTapped
        case refundBannerDismissed
        case refundFlow(PresentationAction<RefundFlowFeature.Action>)
        case delegate(Delegate)

        @CasePathable
        enum Delegate {
            case dismissed
        }
    }

    @Dependency(\.realtimeClient) var realtimeClient
    @Dependency(\.dataControllerClient) var dataController

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard let tripID = state.journey.idVehiculeJourney else { return .none }

                #if DEBUG
                // DEBUG short-circuit: when the user inserted a mock journey
                // via the debug menu, skip the network and read the RT status
                // from the in-memory mock cache.
                if let mockStatus = MockJourneyFactory.realtimeStatus(forTripID: tripID) {
                    state.realtimeStatus = mockStatus
                    return .none
                }
                #endif

                // Capture all needed scalars outside the escaping closure
                // (Reducer state is `inout` and can't cross the await boundary).
                let source = AppFeature.apiSource(for: state.journey)
                let depID = state.journeyStopID(.departure)
                let arrID = state.journeyStopID(.arrival)
                let routeUUID = state.journey.routeUUID
                let stopIDs = state.journey.allStopIDs
                return .run { send in
                    let update = try? await realtimeClient.fetchTripUpdate(tripID, source)
                    // Fetch ALL alerts for the source (no server-side filter)
                    // and apply our own permissive matching: tripID OR
                    // routeID OR any stopID. Lots of SNCF TER disruption
                    // alerts are line-scoped and have no tripID — strict
                    // tripID filtering would silently drop them.
                    let allAlerts = (try? await realtimeClient.fetchAlerts(source, nil)) ?? []
                    let relevant = allAlerts.filter { alert in
                        alert.affects(tripID: tripID, routeID: routeUUID, stopIDs: stopIDs)
                    }
                    let status = AppFeature.buildStatus(
                        tripID: tripID,
                        tripUpdate: update ?? nil,
                        vehiclePosition: nil,
                        alerts: relevant,
                        departureStopID: depID,
                        arrivalStopID: arrID
                    )
                    await send(.realtimeStatusFetched(status))
                }

            case .realtimeStatusFetched(let status):
                state.realtimeStatus = status
                return .none

            case .refundBannerTapped:
                state.refundFlow = state.refundFlowState
                return .none

            case .refundBannerDismissed:
                guard let id = state.journey.id else { return .none }
                // Optimistic local update so the banner disappears immediately;
                // SwiftData write happens in the background.
                state.journey.refundBannerDismissed = true
                return .run { _ in
                    await dataController.setRefundBannerDismissed(id, true)
                }

            case .refundFlow:
                return .none

            case .onDisappear:
                return .send(.delegate(.dismissed))

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$refundFlow, action: \.refundFlow) {
            RefundFlowFeature()
        }
    }
}

// MARK: - Stop-ID helpers (used by onAppear)

extension JourneyDetailFeature.State {
    enum StopRole { case departure, arrival }

    /// Resolves the GTFS stop ID matching the user's departure or arrival
    /// stop. Used to attach the right delay value when folding GTFS-RT data
    /// (since `RealtimeStatus.{departure,arrival}DelaySeconds` are computed
    /// from the matching `StopTimeUpdate.stopID`).
    func journeyStopID(_ role: StopRole) -> String? {
        let target: String = (role == .departure) ? "departure" : "arrival"
        return journey.stops?
            .first(where: { $0.status?.lowercased() == target })?
            .stopinfo?.id
    }
}
