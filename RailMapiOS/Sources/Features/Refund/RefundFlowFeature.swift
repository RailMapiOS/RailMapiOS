//
//  RefundFlowFeature.swift
//  RailMapiOS
//
//  TCA reducer for the refund-claim flow:
//  - Presents the operator's claim form in a WKWebView.
//  - Surfaces a top sheet of "info chips" (PNR, train#, date, departure,
//    arrival, delay) — each chip taps to copy its value to the clipboard
//    so the user pastes into the form fields below in one tap.
//  - The chip carousel is a paged TabView; in V1 the user swipes manually.
//    A future JS bridge can auto-advance when a specific input is focused.
//

import ComposableArchitecture
import Foundation

@Reducer
struct RefundFlowFeature {
    @ObservableState
    struct State: Equatable {
        /// Operator's refund form URL (loaded into the WebView).
        let claimURL: URL

        /// Human-readable operator name (shown in the toolbar).
        let operatorName: String

        /// `true` when the operator's form requires sign-in first. Surfaced
        /// as a banner on top of the WebView before navigation completes.
        let requiresLogin: Bool

        /// PNR / booking reference. Optional because the user may not have
        /// entered one yet (we'll prompt before opening the flow in a follow-up).
        let bookingReference: String?

        /// Train number (`headsign`).
        let trainNumber: String

        /// Departure date — full date+time of the journey.
        let journeyDate: Date

        /// Departure station label (the full name as published by GTFS).
        let departureLabel: String

        /// Arrival station label.
        let arrivalLabel: String

        /// Measured arrival delay in minutes. May be 0 if user opens the
        /// flow before realtime data is available.
        let delayMinutes: Int

        /// Currently visible chip in the paged carousel. Two-way binding
        /// from the View.
        var selectedChipIndex: Int = 0

        /// Last chip the user copied — used to flash a brief "Copied" hint.
        var lastCopiedChipID: ChipID?
    }

    /// Stable IDs for each chip — also used as ForEach IDs in the View.
    enum ChipID: String, CaseIterable, Equatable, Sendable {
        case bookingReference
        case trainNumber
        case journeyDate
        case departure
        case arrival
        case delayMinutes
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case chipTapped(ChipID, value: String)
        case chipCopiedHintExpired(ChipID)
        case dismissTapped
        case delegate(Delegate)

        @CasePathable
        enum Delegate {
            case dismissed
        }
    }

    @Dependency(\.continuousClock) var clock
    @Dependency(\.dismiss) var dismiss

    private enum CancelID: Hashable { case copiedHint }

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .chipTapped(let id, let value):
                // Side effect: copy to the system clipboard. Pure-Swift here
                // (no UIKit import) — UIPasteboard is wrapped in the View
                // so the reducer stays platform-agnostic and testable.
                state.lastCopiedChipID = id
                return .run { send in
                    try? await clock.sleep(for: .seconds(2))
                    await send(.chipCopiedHintExpired(id))
                }
                .cancellable(id: CancelID.copiedHint, cancelInFlight: true)

            case .chipCopiedHintExpired(let id):
                if state.lastCopiedChipID == id {
                    state.lastCopiedChipID = nil
                }
                return .none

            case .dismissTapped:
                // `@Dependency(\.dismiss)` dismisses any presented child reducer
                // — sets the parent's `@Presents` slot back to nil, which in
                // turn closes the `.fullScreenCover` bound to it.
                return .run { _ in await dismiss() }

            case .binding, .delegate:
                return .none
            }
        }
    }
}
