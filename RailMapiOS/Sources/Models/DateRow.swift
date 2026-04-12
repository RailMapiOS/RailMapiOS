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
              let startDate = combineDateWithTime(date: date, timeString: departureStop.utcDepartureTime),
              let endDate = combineDateWithTime(date: date, timeString: arrivalStop.utcArrivalTime) else {
            return nil
        }

        let stops = journey.stopTimes.compactMap { stopTime -> NewStop? in
            guard let arrivalTime = combineDateWithTime(date: date, timeString: stopTime.utcArrivalTime),
                  let departureTime = combineDateWithTime(date: date, timeString: stopTime.utcDepartureTime) else {
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

    private func combineDateWithTime(date: Date, timeString: String?) -> Date? {
        guard let timeString = timeString else { return nil }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let fullDateString = String(format: "%04d-%02d-%02d %@", components.year ?? 2000, components.month ?? 1, components.day ?? 1, timeString)
        return dateFormatter.date(from: fullDateString)
    }
}
