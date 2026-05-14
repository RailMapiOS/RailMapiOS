//
//  StationRow.swift
//  RailMapiOS
//

import SwiftUI

enum PickerModeStation: Equatable {
    case pickUpDeparture
    case dropOffArrival
}

struct StationRow: View {
    let stopTime: StopTime
    let cityName: String?
    let isSelected: Bool
    let isSelectable: Bool

    private static let formatter = DateFormatterService()

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(stopTime.stopPoint.name)
                    .font(.headline)
                HStack {
                    if let cityName = cityName {
                        Text(cityName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Text(Self.formatter.formattedHour(from: stopTime.departureTime))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .blue : .secondary.opacity(0.4))
                .font(.title3)
        }
        .opacity(isSelectable ? 1 : 0.5)
        .contentShape(Rectangle())
    }
}
