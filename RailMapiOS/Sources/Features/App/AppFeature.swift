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

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.map == rhs.map &&
            lhs.bottomSheet == rhs.bottomSheet &&
            lhs.isSheetPresented == rhs.isSheetPresented &&
            lhs.sheetSize == rhs.sheetSize
        }
    }

    enum Action {
        case map(MapFeature.Action)
        case bottomSheet(BottomSheetFeature.Action)
        case journeysLoaded([Journey])
        case sheetSizeChanged(PresentationDetent)
    }

    @Dependency(\.mapClient) var mapClient

    var body: some ReducerOf<Self> {
        Scope(state: \.map, action: \.map) { MapFeature() }
        Scope(state: \.bottomSheet, action: \.bottomSheet) { BottomSheetFeature() }

        Reduce { state, action in
            switch action {
            // MARK: - Journeys sync (SwiftData → Map + BottomSheet)

            case .journeysLoaded(let journeys):
                return .merge(
                    .send(.map(.journeysUpdated(journeys))),
                    .send(.bottomSheet(.journeysUpdated(journeys)))
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

            // MARK: - Passthrough

            case .map, .bottomSheet:
                return .none
            }
        }
    }
}
