//
//  AddTicketView.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 19/07/2024.
//

import SwiftUI

struct AddTicketView: View {
    @StateObject var viewModel = AddTicketVM()
    @ObservedObject var router: Router

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataController: DataController
    @Binding var searchText: String

    @State private var debounceTask: Task<Void, Never>?
    @State private var hasAutoNavigated = false

    var body: some View {
        VStack {
            if viewModel.vehicleJourneys.isEmpty && searchText == "" {
                EmptyListJourneyView()
                    .accessibilityIdentifier(AccessibilityID.AddTicketView.emptyState)
            } else if viewModel.vehicleJourneys.isEmpty {
                EmptyListJourneyView(title: "No Journey found!", subtitle: "Try searching for another journey")
                    .accessibilityIdentifier(AccessibilityID.AddTicketView.noJourneyFounded)
            } else if viewModel.vehicleJourneys.count > 1 {
                // Multiple results: let user pick
                journeyResults
            } else {
                // Single result: waiting for auto-navigate
                ProgressView()
            }
        }
        .accessibilityIdentifier(AccessibilityID.AddTicketView.vStack)
        .onChange(of: searchText) { newValue in
            hasAutoNavigated = false
            debounceTask?.cancel()
            debounceTask = Task {
                try? await Task.sleep(for: .milliseconds(400))
                guard !Task.isCancelled else { return }
                await viewModel.fetchHeadsignAddTicket(headsign: newValue)
            }
        }
        .onChange(of: viewModel.vehicleJourneys) { journeys in
            guard !hasAutoNavigated, journeys.count == 1, let journey = journeys.first else { return }
            hasAutoNavigated = true
            navigateToStationPicker(for: journey)
        }
    }

    // MARK: - Multiple results list

    private var journeyResults: some View {
        List(viewModel.vehicleJourneys, id: \.id) { journey in
            Button {
                navigateToStationPicker(for: journey)
            } label: {
                HStack(spacing: 12) {
                    if let company = SearchJourneyDataSource.companyName(from: journey) {
                        CompanyLogo(company, size: CGSize(width: 28, height: 28))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(journey.headsign)
                            .font(.headline)
                        Text("\(journey.stopTimes.first?.stopPoint.name ?? "") → \(journey.stopTimes.last?.stopPoint.name ?? "")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .listStyle(.plain)
    }

    // MARK: - Navigation

    private func navigateToStationPicker(for journey: VehicleJourney) {
        let templateRow = DateRow(
            journeyId: journey.id,
            date: Date(),
            journey: journey
        )
        router.navigate(to: .stationPicker(templateRow))
    }
}
