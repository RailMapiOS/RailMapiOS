//
//  DatePickerView.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 17/01/2025.
//

import SwiftUI

struct DatePickerView: View {
    @EnvironmentObject var dataController: DataController

    @ObservedObject var viewModel: DatePickerViewModel
    @ObservedObject var router: Router

    @State private var displayedMonth: Date = Date()
    @State private var selectedDate: DateRow?

    var onNext: (DateRow) -> Void

    private var referenceRow: DateRow? { viewModel.dateRows.first }

    private var availableDates: Set<DateComponents> {
        Set(viewModel.dateRows.map { Calendar.current.dateComponents([.year, .month, .day], from: $0.date) })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Fixed journey card
            if let row = referenceRow {
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
                        .accessibilityIdentifier(AccessibilityID.DatePickerView.title)

                    calendarGrid
                        .padding(.horizontal, 8)
                }
            }
        }
        .navigationTitle("Date du voyage")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let selected = selectedDate {
                    Button("Confirmer") {
                        onNext(selected)
                    }
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
                Button { changeMonth(by: -1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                }
                Spacer()
                Text(monthYearString(from: displayedMonth))
                    .font(.headline)
                Spacer()
                Button { changeMonth(by: 1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.semibold))
                }
            }
            .padding(.horizontal, 8)

            // Weekday headers
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Day cells
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 6) {
                ForEach(daysInMonth(), id: \.self) { dayInfo in
                    if let date = dayInfo.date {
                        let isAvailable = isDateAvailable(date)
                        let isSelected = isDateSelected(date)

                        Button {
                            if isAvailable { selectDate(date) }
                        } label: {
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
                                    Circle()
                                        .fill(isSelected ? Color.accentColor : isAvailable ? Color.accentColor.opacity(0.12) : .clear)
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(!isAvailable)
                        .accessibilityIdentifier(AccessibilityID.DatePickerView.dateRow(for: date))
                    } else {
                        Color.clear
                            .frame(width: 40, height: 40)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        let symbols = formatter.veryShortWeekdaySymbols ?? ["S", "M", "T", "W", "T", "F", "S"]
        let firstWeekday = Calendar.current.firstWeekday
        let reordered = Array(symbols[(firstWeekday - 1)...]) + Array(symbols[0..<(firstWeekday - 1)])
        return reordered
    }

    private struct DayInfo: Hashable {
        let date: Date?
        let index: Int
    }

    private func daysInMonth() -> [DayInfo] {
        let cal = Calendar.current
        guard let range = cal.range(of: .day, in: .month, for: displayedMonth),
              let firstOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: displayedMonth)) else {
            return []
        }

        let firstWeekday = cal.component(.weekday, from: firstOfMonth)
        let offset = (firstWeekday - cal.firstWeekday + 7) % 7

        var days: [DayInfo] = []

        // Empty cells before first day
        for i in 0..<offset {
            days.append(DayInfo(date: nil, index: i))
        }

        // Actual days
        for day in range {
            if let date = cal.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(DayInfo(date: date, index: offset + day))
            }
        }

        return days
    }

    private func isDateAvailable(_ date: Date) -> Bool {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return availableDates.contains(components)
    }

    private func isDateSelected(_ date: Date) -> Bool {
        guard let selected = selectedDate else { return false }
        return Calendar.current.isDate(selected.date, inSameDayAs: date)
    }

    private func selectDate(_ date: Date) {
        selectedDate = viewModel.dateRows.first {
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }
    }

    private func changeMonth(by value: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }

    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale.current
        return formatter.string(from: date).capitalized
    }
}
