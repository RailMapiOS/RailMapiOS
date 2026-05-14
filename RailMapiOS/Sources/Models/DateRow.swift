//
//  DateRow.swift
//  RailMapiOS
//
//  Data model representing a journey on a specific date,
//  with optional departure/arrival station selections.
//

import Foundation

struct DateRow: Identifiable, Hashable {
    let id: UUID = UUID()
    let journeyId: String
    let date: Date
    let journey: VehicleJourney
    var departureStationID: String?
    var arrivalStationID: String?

    var company: String? {
        let parts = self.journey.stopTimes.first?.stopPoint.id.components(separatedBy: " ")
        if let parts = parts, parts.count > 1 {
            return parts[1].components(separatedBy: "-").first
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
        lhs.id == rhs.id && lhs.journeyId == rhs.journeyId && lhs.date == rhs.date
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(journeyId)
        hasher.combine(date)
    }
}

// MARK: - Conversion to NewJourneyModel

extension DateRow {
    func toNewJourneyModel() -> NewJourneyModel? {
        guard let departureID = departureStationID,
              let arrivalID = arrivalStationID,
              let departureStop = journey.stopTimes.first(where: { $0.stopPoint.id == departureID }),
              let arrivalStop = journey.stopTimes.first(where: { $0.stopPoint.id == arrivalID }),
              let startDate = combineDateWithTime(date: date, timeString: departureStop.departureTime),
              let endDate = combineDateWithTime(date: date, timeString: arrivalStop.arrivalTime) else {
            return nil
        }

        let stops = journey.stopTimes.compactMap { stopTime -> NewStop? in
            guard let arrivalTime = combineDateWithTime(date: date, timeString: stopTime.arrivalTime),
                  let departureTime = combineDateWithTime(date: date, timeString: stopTime.departureTime) else {
                return nil
            }

            let status: String = {
                if stopTime.stopPoint.id == departureID { return "departure" }
                else if stopTime.stopPoint.id == arrivalID { return "arrival" }
                else { return "" }
            }()

            return NewStop(
                arrivalTimeUTC: arrivalTime,
                departureTimeUTC: departureTime,
                status: status,
                stopInfo: NewStopInfo(
                    id: stopTime.stopPoint.id,
                    label: stopTime.stopPoint.label,
                    latitude: stopTime.stopPoint.coord.lat.convertToDouble() ?? 0.0,
                    longitude: stopTime.stopPoint.coord.lon.convertToDouble() ?? 0.0,
                    adress: "N/A",
                    pickUpAllowed: stopTime.pickupAllowed,
                    dropOffAllowed: stopTime.dropOffAllowed,
                    skippedStop: stopTime.skippedStop
                )
            )
        }

        return NewJourneyModel(
            startDate: startDate,
            endDate: endDate,
            headsign: journey.headsign,
            idVehicleJourney: journey.id,
            company: company ?? "Unknown",
            stops: stops
        )
    }

    /// Combines a calendar date with an Navitia time string.
    /// Navitia API gives times in "HHmmss" (no separators) for the operator's local timezone.
    /// We assume Europe/Paris (the default for SNCF/SNCB/Trenitalia France) since the dataset
    /// is France-centric. For multi-timezone trips, store the operator timezone per journey later.
    private func combineDateWithTime(date: Date, timeString: String?) -> Date? {
        guard let timeString = timeString, !timeString.isEmpty else { return nil }

        // Navitia returns "HHmmss" (e.g. "174000"). Normalize to "HH:mm:ss".
        let normalized: String = {
            if timeString.contains(":") { return timeString }
            guard timeString.count >= 6 else { return timeString }
            let h = timeString.prefix(2)
            let m = timeString.dropFirst(2).prefix(2)
            let s = timeString.dropFirst(4).prefix(2)
            return "\(h):\(m):\(s)"
        }()

        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd HH:mm:ss"
        parser.timeZone = TimeZone(identifier: "Europe/Paris")
        parser.locale = Locale(identifier: "en_US_POSIX")

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let fullDateString = String(
            format: "%04d-%02d-%02d %@",
            components.year ?? 2000,
            components.month ?? 1,
            components.day ?? 1,
            normalized
        )
        return parser.date(from: fullDateString)
    }
}
