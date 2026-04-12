//
//  StationPickerFeature.swift
//  RailMapiOS
//

import ComposableArchitecture
import Foundation

@Reducer
struct StationPickerFeature {
    @ObservableState
    struct State: Equatable {
        // VehicleJourney contains JSONAnyVJ which isn't Equatable
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.journey.id == rhs.journey.id &&
            lhs.departureStation == rhs.departureStation &&
            lhs.arrivalStation == rhs.arrivalStation &&
            lhs.pickerMode == rhs.pickerMode &&
            lhs.cityNames == rhs.cityNames
        }

        var journey: VehicleJourney
        var departureStation: String?
        var arrivalStation: String?
        var pickerMode: PickerModeStation = .pickUpDeparture
        var cityNames: [String: String] = [:]

        // MARK: - Computed card data

        var cardDepartureName: String {
            resolvedStop(for: departureStation, fallback: journey.stopTimes.first)?.stopPoint.name ?? "N/A"
        }

        var cardArrivalName: String {
            resolvedStop(for: arrivalStation, fallback: journey.stopTimes.last)?.stopPoint.name ?? "N/A"
        }

        var cardDepartureTime: String {
            resolvedStop(for: departureStation, fallback: journey.stopTimes.first)?.departureTime ?? ""
        }

        var cardArrivalTime: String {
            resolvedStop(for: arrivalStation, fallback: journey.stopTimes.last)?.arrivalTime ?? ""
        }

        var hasStationsSelected: Bool {
            departureStation != nil && arrivalStation != nil
        }

        var navigationTitle: String {
            pickerMode == .pickUpDeparture ? "Gare de départ" : "Gare d'arrivée"
        }

        private func resolvedStop(for id: String?, fallback: StopTime?) -> StopTime? {
            guard let id else { return fallback }
            return journey.stopTimes.first { $0.stopPoint.id == id } ?? fallback
        }
    }

    enum Action {
        case stationTapped(StopTime)
        case confirmTapped
        case cityNameResolved(stopPointID: String, city: String)
        case delegate(Delegate)

        @CasePathable
        enum Delegate {
            case stationsConfirmed(DateRow)
        }
    }

    @Dependency(\.geocoderClient) var geocoder

    private enum CancelID { case geocoding }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .stationTapped(let stopTime):
                let stopID = stopTime.stopPoint.id

                switch state.pickerMode {
                case .pickUpDeparture:
                    if state.departureStation == stopID {
                        state.departureStation = nil
                        state.arrivalStation = nil
                        state.pickerMode = .pickUpDeparture
                    } else {
                        state.departureStation = stopID
                        state.pickerMode = .dropOffArrival
                    }

                case .dropOffArrival:
                    if state.arrivalStation == stopID {
                        state.arrivalStation = nil
                    } else if state.departureStation != stopID {
                        state.arrivalStation = stopID
                    }
                }

                // Fetch city name if not cached
                if state.cityNames[stopID] == nil {
                    return .run { [coord = stopTime.stopPoint.coord] send in
                        guard let lat = Double(coord.lat), let lon = Double(coord.lon) else { return }
                        if let city = try? await geocoder.reverseGeocode(lat, lon) {
                            await send(.cityNameResolved(stopPointID: stopID, city: city))
                        }
                    }
                }
                return .none

            case .confirmTapped:
                guard let depID = state.departureStation, let arrID = state.arrivalStation else { return .none }
                var dateRow = DateRow(journeyId: state.journey.id, date: Date(), journey: state.journey)
                dateRow.departureStationID = depID
                dateRow.arrivalStationID = arrID
                return .send(.delegate(.stationsConfirmed(dateRow)))

            case .cityNameResolved(let stopPointID, let city):
                state.cityNames[stopPointID] = city
                return .none

            case .delegate:
                return .none
            }
        }
    }

    // MARK: - Station selectability

    static func isStationSelectable(_ stopTime: StopTime, mode: PickerModeStation, departureStation: String?, journey: VehicleJourney) -> Bool {
        switch mode {
        case .pickUpDeparture:
            return stopTime.pickupAllowed
        case .dropOffArrival:
            guard let depID = departureStation,
                  let depIdx = journey.stopTimes.firstIndex(where: { $0.stopPoint.id == depID }),
                  let curIdx = journey.stopTimes.firstIndex(where: { $0.stopPoint.id == stopTime.stopPoint.id }) else {
                return false
            }
            return curIdx > depIdx && stopTime.dropOffAllowed
        }
    }
}
