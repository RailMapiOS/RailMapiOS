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
        static func == (lhs: Self, rhs: Self) -> Bool { lhs.journey.id == rhs.journey.id }

        var journey: Journey

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
    }

    enum Action {
        case onDisappear
        case delegate(Delegate)

        @CasePathable
        enum Delegate {
            case dismissed
        }
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onDisappear:
                return .send(.delegate(.dismissed))
            case .delegate:
                return .none
            }
        }
    }
}
