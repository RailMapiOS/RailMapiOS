//
//  JourneyDetailView.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 19/07/2024.
//

import SwiftUI
import SwiftData

struct JourneyDetailView: View {
    @EnvironmentObject var dataController: DataController
    let journey: Journey

    var departureLabel: String {
        guard let stops = journey.stops,
              let departureStop = stops.first(where: { $0.status == "departure" }) else {
            return "N/A"
        }
        return departureStop.stopinfo?.label ?? "N/A"
    }

    var arrivalLabel: String {
        guard let stops = journey.stops,
              let arrivalStop = stops.first(where: { $0.status == "arrival" }) else {
            return "N/A"
        }
        return arrivalStop.stopinfo?.label ?? "N/A"
    }

    private var journeyStatus: DepartureStatusView.DepartureStatus {
        guard let startDate = journey.startDate else { return .unknown }
        let now = Date()
        if now > startDate { return .intime }
        return .intime
    }

    private var stopsCount: Int {
        journey.stops?.count ?? 0
    }

    var body: some View {
        VStack(spacing: 0) {
            JourneyHeaderView(
                company: journey.company,
                headsign: journey.headsign,
                departureCity: departureLabel,
                arrivalCity: arrivalLabel,
                departureDate: journey.startDate,
                size: CGSize(width: 60, height: 60)
            )

            Divider()

            ScrollView {
                VStack(spacing: 16) {
                    // Departure Status
                    if let startDate = journey.startDate {
                        DepartureStatusView(
                            status: journeyStatus,
                            time: startDate,
                            station: departureLabel,
                            hall: nil,
                            platform: nil
                        )
                    }

                    // Route timeline
                    VStack {
                        StationView(
                            stationLabel: departureLabel,
                            date: journey.startDate ?? Date(),
                            arrival: false
                        )

                        DurationView(
                            startDate: journey.startDate,
                            endDate: journey.endDate
                        )

                        StationView(
                            stationLabel: arrivalLabel,
                            date: journey.endDate ?? Date(),
                            arrival: true
                        )
                    }
                    .padding(.vertical)

                    // Booking info
                    HStack {
                        InfoCard(
                            title: "Booking Code",
                            bodyTexts: ["Tap to Edit"],
                            icon: "ticket.fill",
                            displayMode: .small
                        )

                        InfoCard(
                            title: "Seat",
                            bodyTexts: ["Tap to Edit"],
                            icon: "carseat.right.fill",
                            displayMode: .small
                        )
                    }
                    .padding(.horizontal)

                    // Route info
                    if stopsCount > 2 {
                        InfoCard(
                            header: "Route Info",
                            title: "\(stopsCount) stops",
                            bodyTexts: ["\(departureLabel) → \(arrivalLabel)"],
                            icon: "point.topright.arrow.triangle.backward.to.point.bottomleft.scurvepath.fill"
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
        }
    }
}

// Preview
#Preview {
    let journey = Journey()
    journey.id = UUID()
    journey.headsign = "Paris -> Lyon"
    journey.company = "SNCF"
    journey.startDate = Date()
    journey.endDate = Date().addingTimeInterval(3600)
    journey.archived = false

    let departureStopInfo = StopInfos()
    departureStopInfo.id = UUID().uuidString
    departureStopInfo.label = "Gare de Lyon"
    departureStopInfo.latitude = 48.8444
    departureStopInfo.longitude = 2.3732

    let departureStop = Stop()
    departureStop.arrivalTimeUTC = journey.startDate
    departureStop.departureTimeUTC = journey.startDate
    departureStop.status = "departure"
    departureStop.stopinfo = departureStopInfo
    departureStopInfo.stop = departureStop

    let arrivalStopInfo = StopInfos()
    arrivalStopInfo.id = UUID().uuidString
    arrivalStopInfo.label = "Gare de Lyon Part-Dieu"
    arrivalStopInfo.latitude = 45.7603
    arrivalStopInfo.longitude = 4.8590

    let arrivalStop = Stop()
    arrivalStop.arrivalTimeUTC = journey.endDate
    arrivalStop.departureTimeUTC = journey.endDate
    arrivalStop.status = "arrival"
    arrivalStop.stopinfo = arrivalStopInfo
    arrivalStopInfo.stop = arrivalStop

    journey.stops = [departureStop, arrivalStop]

    return JourneyDetailView(journey: journey)
        .environmentObject(DataController())
}
