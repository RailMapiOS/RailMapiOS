//
//  ConfirmationPickerView.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 19/01/2025.
//

import SwiftUI

struct ConfirmationPickerView: View {
    @EnvironmentObject var dataController: DataController
    @ObservedObject var viewModel: ConfirmationPickerViewModel

    var onNext: () -> Void

    private var departureLabel: String {
        viewModel.departureStationInfo?.stopPoint.name ?? "N/A"
    }

    private var arrivalLabel: String {
        viewModel.arrivalStationInfo?.stopPoint.label ?? "N/A"
    }

    var body: some View {
        VStack(spacing: 0) {
            JourneyHeaderView(
                company: viewModel.pickedJourney.company,
                headsign: viewModel.pickedJourney.journey.headsign,
                departureCity: departureLabel,
                arrivalCity: arrivalLabel,
                departureDate: viewModel.pickedJourney.date,
                size: CGSize(width: 60, height: 60)
            )
            .accessibilityIdentifier(AccessibilityID.ConfirmationPickerView.header)

            Divider()

            ScrollView {
                VStack(spacing: 16) {
                    // Route timeline
                    if let depInfo = viewModel.departureStationInfo,
                       let arrInfo = viewModel.arrivalStationInfo,
                       let depDate = viewModel.convertToDate(from: depInfo.departureTime, using: viewModel.pickedJourney.date),
                       let arrDate = viewModel.convertToDate(from: arrInfo.arrivalTime, using: viewModel.pickedJourney.date) {

                        VStack {
                            StationView(stationLabel: depInfo.stopPoint.name, date: depDate, arrival: false)
                                .accessibilityIdentifier(AccessibilityID.ConfirmationPickerView.departureStationView)

                            DurationView(startDate: depDate, endDate: arrDate)
                                .accessibilityIdentifier(AccessibilityID.ConfirmationPickerView.durationView)

                            StationView(stationLabel: arrInfo.stopPoint.label, date: arrDate, arrival: true)
                                .accessibilityIdentifier(AccessibilityID.ConfirmationPickerView.arrivalStationView)
                        }
                        .padding(.vertical)
                    }

                    // Booking info
                    HStack {
                        InfoCard(
                            title: "Booking Code",
                            bodyTexts: ["Tap to Edit"],
                            icon: "ticket.fill",
                            displayMode: .small
                        )
                        .accessibilityIdentifier(AccessibilityID.ConfirmationPickerView.bookingCodeRow)

                        InfoCard(
                            title: "Seat",
                            bodyTexts: ["Tap to Edit"],
                            icon: "carseat.right.fill",
                            displayMode: .small
                        )
                        .accessibilityIdentifier(AccessibilityID.ConfirmationPickerView.seatRow)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .accessibilityIdentifier(AccessibilityID.ConfirmationPickerView.scrollView)
        }
        .navigationTitle("Confirmation")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Confirmer") {
                    let newJourney = viewModel.pickedJourney.toNewJourneyModel()
                    if let newJourney = newJourney {
                        viewModel.saveNewJourney(newJourney)
                        onNext()
                    }
                }
                .accessibilityIdentifier(AccessibilityID.ConfirmationPickerView.confirmButton)
                .font(.headline)
            }
        }
    }
}
