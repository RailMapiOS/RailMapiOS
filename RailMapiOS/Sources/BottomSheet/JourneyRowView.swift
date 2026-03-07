//
//  JourneyRowView.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 12/07/2024.
//

import SwiftData
import SwiftUI

struct JourneyRowView: View {
    @StateObject private var viewModel: JourneyRowViewModel

    init(journey: Journey) {
        self._viewModel = StateObject(
            wrappedValue: JourneyRowViewModel(journey: journey)
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: Logo + Train ID + Duration
            HStack(spacing: 8) {
                CompanyLogo(viewModel.company, size: CGSize(width: 28, height: 28))
                Text("\(viewModel.company) \(viewModel.headsign)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                HStack(spacing: 3) {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(viewModel.duration)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()
                .padding(.horizontal, 14)

            // Times & Stations
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.departureTime)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                    Text(viewModel.departureLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(viewModel.arrivalTime)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                    Text(viewModel.arrivalLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider()
                .padding(.horizontal, 14)

            // Footer: Date + Status badge
            HStack {
                Text(viewModel.departureDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                JourneyStatusBadge(status: viewModel.status)
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .contentShape(Rectangle())
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
    }
}

#if DEBUG
#Preview {
    let journey = Journey()
    journey.headsign = "6234"
    journey.company = "SNCF"
    journey.startDate = Date()
    journey.endDate = Date().addingTimeInterval(3600 * 2.25)

    return List {
        JourneyRowView(journey: journey)
        JourneyRowView(journey: journey)
    }
    .listStyle(.plain)
}
#endif
