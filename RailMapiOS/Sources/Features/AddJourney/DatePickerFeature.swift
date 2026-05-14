//
//  DatePickerFeature.swift
//  RailMapiOS
//

import ComposableArchitecture
import Foundation

@Reducer
struct DatePickerFeature {
    @ObservableState
    struct State: Equatable {
        var dateRows: [DateRow]
        var displayedMonth: Date
        var selectedDate: DateRow?

        var referenceRow: DateRow? { dateRows.first }

        var availableDates: Set<DateComponents> {
            Set(dateRows.map { Calendar.current.dateComponents([.year, .month, .day], from: $0.date) })
        }
    }

    enum Action {
        case dateTapped(Date)
        case monthChanged(Int)
        case confirmTapped
        case delegate(Delegate)

        @CasePathable
        enum Delegate {
            case dateSelected(DateRow)
        }
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .dateTapped(let date):
                state.selectedDate = state.dateRows.first {
                    Calendar.current.isDate($0.date, inSameDayAs: date)
                }
                return .none

            case .monthChanged(let offset):
                if let newMonth = Calendar.current.date(byAdding: .month, value: offset, to: state.displayedMonth) {
                    state.displayedMonth = newMonth
                }
                return .none

            case .confirmTapped:
                guard let selected = state.selectedDate else { return .none }
                return .send(.delegate(.dateSelected(selected)))

            case .delegate:
                return .none
            }
        }
    }
}
