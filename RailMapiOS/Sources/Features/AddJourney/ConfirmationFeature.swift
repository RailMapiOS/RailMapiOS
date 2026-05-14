//
//  ConfirmationFeature.swift
//  RailMapiOS
//

import ComposableArchitecture
import Foundation

@Reducer
struct ConfirmationFeature {
    @ObservableState
    struct State: Equatable {
        var pickedJourney: DateRow
        var departureStationInfo: StopTime?
        var arrivalStationInfo: StopTime?

        init(pickedJourney: DateRow) {
            self.pickedJourney = pickedJourney
            self.departureStationInfo = Self.stopInfo(from: pickedJourney.journey, id: pickedJourney.departureStationID)
            self.arrivalStationInfo = Self.stopInfo(from: pickedJourney.journey, id: pickedJourney.arrivalStationID)
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.pickedJourney == rhs.pickedJourney
        }

        private static func stopInfo(from journey: VehicleJourney, id: String?) -> StopTime? {
            guard let id else { return nil }
            return journey.stopTimes.first { $0.stopPoint.id == id }
        }
    }

    enum Action {
        case confirmTapped
        case journeySaved
        case delegate(Delegate)

        @CasePathable
        enum Delegate {
            case journeyConfirmed
        }
    }

    @Dependency(\.dataControllerClient) var dataController

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .confirmTapped:
                guard let newJourney = state.pickedJourney.toNewJourneyModel() else { return .none }
                return .run { [newJourney] send in
                    await dataController.saveJourney(newJourney)
                    await send(.journeySaved)
                }

            case .journeySaved:
                return .send(.delegate(.journeyConfirmed))

            case .delegate:
                return .none
            }
        }
    }

    // MARK: - Helpers

    static func convertToDate(from timeString: String, using baseDate: Date) -> Date? {
        let formats = ["HH:mm:ss", "HHmmss"]
        let calendar = Calendar.current
        let baseComponents = calendar.dateComponents([.year, .month, .day], from: baseDate)

        for format in formats {
            let parser = DateFormatter()
            parser.dateFormat = format
            parser.timeZone = TimeZone.current
            if let timeOnlyDate = parser.date(from: timeString) {
                let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: timeOnlyDate)
                return calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                     minute: timeComponents.minute ?? 0,
                                     second: timeComponents.second ?? 0,
                                     of: calendar.date(from: baseComponents) ?? baseDate)
            }
        }
        return nil
    }
}
