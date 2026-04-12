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
                if let matchingRoute = state.map.trainRoutes.first(where: { route in
                    guard let stops = journey.stops,
                          let firstStop = stops.first(where: { $0.status?.lowercased() == "departure" }),
                          let lastStop = stops.last(where: { $0.status?.lowercased() == "arrival" }),
                          let firstInfo = firstStop.stopinfo,
                          let lastInfo = lastStop.stopinfo,
                          let firstLat = firstInfo.latitude, let firstLon = firstInfo.longitude,
                          let lastLat = lastInfo.latitude, let lastLon = lastInfo.longitude else { return false }

                    let firstCoord = CLLocationCoordinate2D(latitude: firstLat, longitude: firstLon)
                    let lastCoord = CLLocationCoordinate2D(latitude: lastLat, longitude: lastLon)
                    return route.stopCoordinates.first == firstCoord && route.stopCoordinates.last == lastCoord
                }) {
                    return .send(.map(.selectRoute(matchingRoute)))
                }
                return .none

            // MARK: - Clear route selection on nav back

            case .bottomSheet(.path(.element(_, action: .journeyDetail(.delegate(.dismissed))))):
                return .send(.map(.clearRouteSelection))

            // MARK: - Passthrough

            case .map, .bottomSheet:
                return .none
            }
        }
    }
}
