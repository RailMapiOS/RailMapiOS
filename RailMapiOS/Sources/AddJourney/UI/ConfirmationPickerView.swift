//
//  ConfirmationView.swift
//  RailMapiOS
//

import ComposableArchitecture
import SwiftUI

struct ConfirmationView: View {
    let store: StoreOf<ConfirmationFeature>

    private var departureLabel: String {
        store.departureStationInfo?.stopPoint.name ?? "N/A"
    }

    private var arrivalLabel: String {
        store.arrivalStationInfo?.stopPoint.label ?? "N/A"
    }

    var body: some View {
        VStack(spacing: 0) {
            JourneyHeaderView(
                company: store.pickedJourney.company,
                headsign: store.pickedJourney.journey.headsign,
                departureCity: departureLabel,
                arrivalCity: arrivalLabel,
                departureDate: store.pickedJourney.date,
                size: CGSize(width: 60, height: 60)
            )

            Divider()

            ScrollView {
                VStack(spacing: 16) {
                    if let depInfo = store.departureStationInfo,
                       let arrInfo = store.arrivalStationInfo,
                       let depDate = ConfirmationFeature.convertToDate(from: depInfo.departureTime, using: store.pickedJourney.date),
                       let arrDate = ConfirmationFeature.convertToDate(from: arrInfo.arrivalTime, using: store.pickedJourney.date) {

                        VStack {
                            StationView(stationLabel: depInfo.stopPoint.name, date: depDate, arrival: false)
                            DurationView(startDate: depDate, endDate: arrDate)
                            StationView(stationLabel: arrInfo.stopPoint.label, date: arrDate, arrival: true)
                        }
                        .padding(.vertical)
                    }

                    // Booking code & seat: hidden until edit is implemented.
                    // TODO: re-enable when sheet for editing is added.
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Summary")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Add to my journeys") { store.send(.confirmTapped) }
                    .font(.headline)
            }
        }
    }
}
