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
        case routeGeometryResolved(routeID: UUID, coordinates: [CLLocationCoordinate2D], source: String, journey: Journey?)
        case routeGeometryFailed(routeID: UUID)
    }

    @Dependency(\.routeGeometryClient) var routeGeometry
    @Dependency(\.dataControllerClient) var dataController

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .journeysUpdated(let journeys):
                state.journeys = journeys
                state.trainRoutes = Self.generateTrainRoutes(from: journeys)
                state.cameraUpdateTrigger += 1
                return resolveGeometries(for: &state)

            case .selectRoute(let route):
                state.selectedRoute = route
                state.cameraUpdateTrigger += 1
                return .none

            case .clearRouteSelection:
                state.selectedRoute = nil
                state.cameraUpdateTrigger += 1
                return .none

            case .routeGeometryResolved(let routeID, let coordinates, let source, let journey):
                if let index = state.trainRoutes.firstIndex(where: { $0.id == routeID }),
                   coordinates.count > state.trainRoutes[index].stopCoordinates.count {
                    state.trainRoutes[index].routeCoordinates = coordinates
                    // Persist shape
                    if let journey {
                        return .run { [journey, coordinates, source] _ in
                            await dataController.saveRouteShape(journey, coordinates, source)
                        }
                    }
                }
                return .none

            case .routeGeometryFailed:
                return .none
            }
        }
    }

    // MARK: - Route Generation (pure logic, extracted from MapSettings)

    static func generateTrainRoutes(from journeys: [Journey]) -> [TrainRoute] {
        journeys.compactMap { journey -> TrainRoute? in
            guard let stops = journey.stops, !stops.isEmpty else { return nil }

            let sortedStops = stops.sorted { s1, s2 in
                (s1.departureTimeUTC ?? s1.arrivalTimeUTC ?? .distantPast) < (s2.departureTimeUTC ?? s2.arrivalTimeUTC ?? .distantPast)
            }

            guard let depIdx = sortedStops.firstIndex(where: { $0.status?.lowercased() == "departure" }),
                  let arrIdx = sortedStops.lastIndex(where: { $0.status?.lowercased() == "arrival" }),
                  depIdx <= arrIdx else { return nil }

            let coordinates = Array(sortedStops[depIdx...arrIdx]).compactMap { stop -> CLLocationCoordinate2D? in
                guard let info = stop.stopinfo, let lat = info.latitude, let lon = info.longitude else { return nil }
                return CLLocationCoordinate2D(latitude: lat, longitude: lon)
            }

            guard coordinates.count >= 2 else { return nil }

            var route = TrainRoute(coordinates: coordinates, company: journey.company, headsign: journey.headsign)
            if let cached = journey.getRouteShape(), cached.count > coordinates.count {
                route.routeCoordinates = cached
            }
            return route
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
            let journey = state.journeys.first { $0.headsign == headsign }

            return .run { send in
                do {
                    let resolved: [CLLocationCoordinate2D]
                    if let headsign {
                        let result = try await routeGeometry.fetchRouteShape(headsign, "sncf-ter")
                        resolved = result.coordinates
                        await send(.routeGeometryResolved(routeID: routeID, coordinates: resolved, source: result.shapeSource, journey: journey))
                    } else {
                        resolved = try await routeGeometry.fetchRouteGeometry(stops)
                        await send(.routeGeometryResolved(routeID: routeID, coordinates: resolved, source: "signal-osrm", journey: journey))
                    }
                } catch {
                    // Fallback to OSRM
                    do {
                        let fallback = try await routeGeometry.fetchRouteGeometry(stops)
                        await send(.routeGeometryResolved(routeID: routeID, coordinates: fallback, source: "signal-osrm", journey: journey))
                    } catch {
                        await send(.routeGeometryFailed(routeID: routeID))
                    }
                }
            }
        })
    }

}
