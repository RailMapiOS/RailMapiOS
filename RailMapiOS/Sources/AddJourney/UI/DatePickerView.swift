//
//  DatePickerView.swift
//  RailMapiOS
//

import ComposableArchitecture
import SwiftUI

struct DatePickerView: View {
    @Bindable var store: StoreOf<DatePickerFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Fixed journey card with validated stations
            if let row = store.referenceRow {
                JourneyRowView(
                    dataSource: SearchJourneyDataSource(
                        journey: row.journey,
                        departureStationID: row.departureStationID,
                        arrivalStationID: row.arrivalStationID
                    )
                )
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }

            // Calendar
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Choisir une date")
                        .fontWeight(.bold)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    calendarGrid
                        .padding(.horizontal, 8)
                }
            }
        }
        .navigationTitle("Date du voyage")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if store.selectedDate != nil {
                    Button("Confirmer") { store.send(.confirmTapped) }
                        .font(.headline)
                }
            }
        }
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        VStack(spacing: 12) {
            // Month navigation
            HStack {
                Button { store.send(.monthChanged(-1)) } label: {
                    Image(systemName: "chevron.left").font(.body.weight(.semibold))
                }
                Spacer()
                Text(monthYearString(from: store.displayedMonth))
                    .font(.headline)
                Spacer()
                Button { store.send(.monthChanged(1)) } label: {
                    Image(systemName: "chevron.right").font(.body.weight(.semibold))
                }
            }
            .padding(.horizontal, 8)

            // Weekday headers
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption2).fontWeight(.medium).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Day cells
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 6) {
                ForEach(daysInMonth(), id: \.self) { dayInfo in
                    if let date = dayInfo.date {
                        let isAvailable = isDateAvailable(date)
                        let isSelected = isDateSelected(date)

                        Button { if isAvailable { store.send(.dateTapped(date)) } } label: {
                            Text("\(Calendar.current.component(.day, from: date))")
                                .font(.body)
                                .fontWeight(isSelected ? .bold : isAvailable ? .medium : .regular)
                                .frame(width: 40, height: 40)
                                .foregroundStyle(
                                    isSelected ? .white :
                                    isAvailable ? .primary :
                                    .secondary.opacity(0.3)
                                )
                                .background(
                                    Circle().fill(isSelected ? Color.accentColor : isAvailable ? Color.accentColor.opacity(0.12) : .clear)
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(!isAvailable)
                    } else {
                        Color.clear.frame(width: 40, height: 40)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        let symbols = formatter.veryShortWeekdaySymbols ?? ["D", "L", "M", "M", "J", "V", "S"]
        let firstWeekday = Calendar.current.firstWeekday
        return Array(symbols[(firstWeekday - 1)...]) + Array(symbols[0..<(firstWeekday - 1)])
    }

    private struct DayInfo: Hashable {
        let date: Date?
        let index: Int
    }

    private func daysInMonth() -> [DayInfo] {
        let cal = Calendar.current
        guard let range = cal.range(of: .day, in: .month, for: store.displayedMonth),
              let firstOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: store.displayedMonth)) else { return [] }

        let firstWeekday = cal.component(.weekday, from: firstOfMonth)
        let offset = (firstWeekday - cal.firstWeekday + 7) % 7

        var days: [DayInfo] = (0..<offset).map { DayInfo(date: nil, index: $0) }
        for day in range {
            if let date = cal.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(DayInfo(date: date, index: offset + day))
            }
        }
        return days
    }

    private func isDateAvailable(_ date: Date) -> Bool {
        store.availableDates.contains(Calendar.current.dateComponents([.year, .month, .day], from: date))
    }

    private func isDateSelected(_ date: Date) -> Bool {
        guard let selected = store.selectedDate else { return false }
        return Calendar.current.isDate(selected.date, inSameDayAs: date)
    }

    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale.current
        return formatter.string(from: date).capitalized
    }
}
