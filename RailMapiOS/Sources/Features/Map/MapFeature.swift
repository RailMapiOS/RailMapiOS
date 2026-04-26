//
//  MapFeature.swift
//  RailMapiOS
//

import ComposableArchitecture
import CoreLocation
import Foundation

@Reducer
struct MapFeature {
    @ObservableState
    struct State: Equatable {
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.trainRoutes == rhs.trainRoutes &&
            lhs.selectedRoute == rhs.selectedRoute &&
            lhs.journeys.compactMap(\.id) == rhs.journeys.compactMap(\.id)
        }

        var trainRoutes: [TrainRoute] = []
        var selectedRoute: TrainRoute?
        var journeys: [Journey] = []
        /// Incremented whenever camera should update — the View reacts to this.
        var cameraUpdateTrigger: Int = 0
    }

    enum Action {
        case journeysUpdated([Journey])
        case selectRoute(TrainRoute?)
        case clearRouteSelection
        case routeGeometryResolved(routeID: UUID, coordinates: [CLLocationCoordinate2D], source: String, journeyID: UUID?)
        case routeGeometryFailed(routeID: UUID)
    }

    @Dependency(\.routeGeometryClient) var routeGeometry
    @Dependency(\.dataControllerClient) var dataController
    @Dependency(\.mapClient) var mapClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .journeysUpdated(let journeys):
                let oldIDs = Set(state.journeys.compactMap(\.id))
                let newIDs = Set(journeys.compactMap(\.id))
                let isSameSet = oldIDs == newIDs && !state.trainRoutes.isEmpty
                state.journeys = journeys
                state.trainRoutes = mapClient.generateTrainRoutes(journeys)
                state.cameraUpdateTrigger += 1
                guard !isSameSet else { return .none }
                return resolveGeometries(for: &state)

            case .selectRoute(let route):
                state.selectedRoute = route
                state.cameraUpdateTrigger += 1
                return .none

            case .clearRouteSelection:
                state.selectedRoute = nil
                state.cameraUpdateTrigger += 1
                return .none

            case .routeGeometryResolved(let routeID, let coordinates, let source, let journeyID):
                if let index = state.trainRoutes.firstIndex(where: { $0.id == routeID }),
                   coordinates.count > state.trainRoutes[index].stopCoordinates.count {
                    state.trainRoutes[index].routeCoordinates = coordinates
                    if let journeyID {
                        return .run { _ in
                            await dataController.saveRouteShape(journeyID, coordinates, source)
                        }
                    }
                }
                return .none

            case .routeGeometryFailed:
                return .none
            }
        }
    }

    // MARK: - Geometry Resolution

    private func resolveGeometries(for state: inout State) -> Effect<Action> {
        let routesToResolve = state.trainRoutes.enumerated().filter { _, route in
            route.stopCoordinates.count >= 2 && route.routeCoordinates.count <= route.stopCoordinates.count
        }

        guard !routesToResolve.isEmpty else { return .none }

        return .merge(routesToResolve.map { _, route in
            let routeID = route.id
            let headsign = route.headsign
            let stops = route.stopCoordinates
            let journeyID = state.journeys.first { $0.headsign == headsign }?.id

            return .run { send in
                do {
                    if let headsign {
                        let result = try await routeGeometry.fetchRouteShape(headsign, "sncf-ter")
                        await send(.routeGeometryResolved(routeID: routeID, coordinates: result.coordinates, source: result.shapeSource, journeyID: journeyID))
                    } else {
                        let resolved = try await routeGeometry.fetchRouteGeometry(stops)
                        await send(.routeGeometryResolved(routeID: routeID, coordinates: resolved, source: "signal-osrm", journeyID: journeyID))
                    }
                } catch {
                    do {
                        let fallback = try await routeGeometry.fetchRouteGeometry(stops)
                        await send(.routeGeometryResolved(routeID: routeID, coordinates: fallback, source: "signal-osrm", journeyID: journeyID))
                    } catch {
                        await send(.routeGeometryFailed(routeID: routeID))
                    }
                }
            }
        })
    }
}
