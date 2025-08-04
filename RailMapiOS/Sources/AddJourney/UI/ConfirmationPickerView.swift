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

    var body: some View {
        JourneyHeaderView(
            company: viewModel.pickedJourney.company,
            headsign: viewModel.pickedJourney.journey.headsign,
            departureCity: viewModel.departureStationInfo?.stopPoint.label,
            arrivalCity: viewModel.arrivalStationInfo?.stopPoint.label,
            departureDate: viewModel.pickedJourney.date,
            size: CGSize(width: 60, height: 60)
        )
        .accessibilityIdentifier(AccessibilityID.ConfirmationPickerView.header)
        
        VStack(spacing: 0) {
            Divider()
            ScrollView(showsIndicators: true) {
                if let DStationInfo = viewModel.departureStationInfo,
                   let AStationInfo = viewModel.arrivalStationInfo,
                   let departureDate = viewModel.convertToDate(from: DStationInfo.arrivalTime, using: viewModel.pickedJourney.date),
                   let arrivalDate = viewModel.convertToDate(from: AStationInfo.arrivalTime, using: viewModel.pickedJourney.date) {
                    VStack{
                        StationView(stationLabel: DStationInfo.stopPoint.name, date: departureDate, arrival: false)
                            .accessibilityIdentifier(AccessibilityID.ConfirmationPickerView.departureStationView)

                        DurationView(startDate: departureDate, endDate : arrivalDate)
                            .accessibilityIdentifier(AccessibilityID.ConfirmationPickerView.durationView)

                        StationView(stationLabel: AStationInfo.stopPoint.label, date: arrivalDate, arrival: true)
                            .accessibilityIdentifier(AccessibilityID.ConfirmationPickerView.arrivalStationView)
                    }
                    .accessibilityIdentifier(AccessibilityID.ConfirmationPickerView.vStack)
                    .padding(.vertical)
                }
                HStack {
                    ClippedRow(
                        title: "Booking Code",
                        bodyTexts: ["Tap to Edit"],
                        icon: "ticket.fill",
                        displayMode: .small
                    )
                    .accessibilityIdentifier(AccessibilityID.ConfirmationPickerView.bookingCodeRow)
                    
                    ClippedRow(
                        title: "Seat",
                        bodyTexts: ["Tap to Edit"],
                        icon: "carseat.right.fill",
                        displayMode: .small
                    )
                    .accessibilityIdentifier(AccessibilityID.ConfirmationPickerView.seatRow)
                }
                .padding()
                
                LazyVStack(alignment: .leading) {
                    Text("Good to know")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    ClippedRow(title: "Prevision à l'arrivée",
                               bodyTexts: ["14°C et ensoleillée"],
                               icon: "cloud.sun.fill"
                    )
                }
                .padding(.horizontal)
                Spacer()
            }
            .accessibilityIdentifier(AccessibilityID.ConfirmationPickerView.scrollView)
            .padding(.top, -15)
            .padding(.vertical)
            Spacer()
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Confirmer") {
                    let newJourney = viewModel.pickedJourney.toNewJourneyModel()
                    if let newJourney = newJourney {
                        DispatchQueue.main.async {
                            viewModel.saveNewJourney(newJourney)
                            onNext()
                        }
                    }
                }
                .accessibilityIdentifier(AccessibilityID.ConfirmationPickerView.confirmButton)
                .font(.headline)
            }
        }
    }
}
