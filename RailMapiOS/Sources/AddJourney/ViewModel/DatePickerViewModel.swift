//
//  DatePickerViewModel.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 17/01/2025.
//

import Foundation

class DatePickerViewModel: ObservableObject {
    @Published var dateRows: [DateRow] = []

    init(dateRows: [DateRow]) {
        self.dateRows = dateRows
    }

    /// Groups date rows by journey, preserving the original VehicleJourney reference.
    var groupedByJourney: [(journey: VehicleJourney, dates: [DateRow])] {
        let grouped = Dictionary(grouping: dateRows) { $0.journeyId }
        return grouped.compactMap { (_, rows) -> (VehicleJourney, [DateRow])? in
            guard let first = rows.first else { return nil }
            return (first.journey, rows.sorted { $0.date < $1.date })
        }
        .sorted { ($0.dates.first?.date ?? .distantFuture) < ($1.dates.first?.date ?? .distantFuture) }
    }
}

struct DateRow: Identifiable, Hashable {
    let id: UUID = UUID()
    let journeyId: String
    let date: Date
    let journey: VehicleJourney
    var departureStationID: String?
    var arrivalStationID: String?
    var company: String? {
        let parts = self.journey.stopTimes.first?.stopPoint.id.components(separatedBy: " ")
        if let parts = parts {
            if parts.count > 1 {
                return parts[1].components(separatedBy: "-").first
            }
        }
        return nil
    }

    var formattedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMM"
        dateFormatter.locale = Locale.current
        return dateFormatter.string(from: date)
    }

    static func == (lhs: DateRow, rhs: DateRow) -> Bool {
        return lhs.id == rhs.id
            && lhs.journeyId == rhs.journeyId
            && lhs.date == rhs.date
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(journeyId)
        hasher.combine(date)
    }
}
