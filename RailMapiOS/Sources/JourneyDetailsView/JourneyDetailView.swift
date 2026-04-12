//
//  JourneyDetailView.swift
//  RailMapiOS
//

import ComposableArchitecture
import SwiftUI

struct JourneyDetailView: View {
    let store: StoreOf<JourneyDetailFeature>

    var body: some View {
        VStack(spacing: 0) {
            JourneyHeaderView(
                company: store.journey.company,
                headsign: store.journey.headsign,
                departureCity: store.departureLabel,
                arrivalCity: store.arrivalLabel,
                departureDate: store.journey.startDate,
                size: CGSize(width: 60, height: 60)
            )

            Divider()

            ScrollView {
                VStack(spacing: 16) {
                    // Route timeline
                    VStack {
                        StationView(
                            stationLabel: store.departureLabel,
                            date: store.journey.startDate ?? Date(),
                            arrival: false
                        )
                        DurationView(
                            startDate: store.journey.startDate,
                            endDate: store.journey.endDate
                        )
                        StationView(
                            stationLabel: store.arrivalLabel,
                            date: store.journey.endDate ?? Date(),
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
                    if store.stopsCount > 2 {
                        InfoCard(
                            header: "Route Info",
                            title: "\(store.stopsCount) stops",
                            bodyTexts: ["\(store.departureLabel) → \(store.arrivalLabel)"],
                            icon: "point.topright.arrow.triangle.backward.to.point.bottomleft.scurvepath.fill"
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
        }
        .onDisappear { store.send(.onDisappear) }
    }
}
