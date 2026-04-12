//
//  StationPickerViewTCA.swift
//  RailMapiOS
//

import ComposableArchitecture
import SwiftUI

struct StationPickerViewTCA: View {
    @Bindable var store: StoreOf<StationPickerFeature>

    private static let formatter = DateFormatterService()

    var body: some View {
        VStack(spacing: 0) {
            // Fixed journey card
            journeyCard
                .padding(.horizontal, 12)
                .padding(.bottom, 8)

            // Station list
            List {
                ForEach(store.journey.stopTimes, id: \.stopPoint.id) { stopTime in
                    let isSelected = stopTime.stopPoint.id == store.departureStation || stopTime.stopPoint.id == store.arrivalStation
                    let isSelectable = StationPickerFeature.isStationSelectable(
                        stopTime, mode: store.pickerMode,
                        departureStation: store.departureStation,
                        journey: store.journey
                    )

                    Button { store.send(.stationTapped(stopTime)) } label: {
                        StationRow(
                            stopTime: stopTime,
                            cityName: store.cityNames[stopTime.stopPoint.id],
                            isSelected: isSelected,
                            isSelectable: isSelectable
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!isSelectable)
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle(store.navigationTitle)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if store.hasStationsSelected {
                    Button("Confirmer") { store.send(.confirmTapped) }
                        .font(.headline)
                }
            }
        }
    }

    // MARK: - Journey Card

    private var journeyCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 8) {
                if let company = SearchJourneyDataSource.companyName(from: store.journey) {
                    CompanyLogo(company, size: CGSize(width: 28, height: 28))
                    Text("\(company) \(store.journey.headsign)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider().padding(.horizontal, 14)

            // Stations
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(store.cardDepartureName)
                        .font(.title2).fontWeight(.semibold)
                        .foregroundStyle(store.departureStation != nil ? .primary : .secondary)
                        .lineLimit(1)
                    Text(Self.formatter.formattedHour(from: store.cardDepartureTime))
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(store.cardArrivalName)
                        .font(.title2).fontWeight(.semibold)
                        .foregroundStyle(store.arrivalStation != nil ? .primary : .secondary)
                        .lineLimit(1)
                    Text(Self.formatter.formattedHour(from: store.cardArrivalTime))
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
