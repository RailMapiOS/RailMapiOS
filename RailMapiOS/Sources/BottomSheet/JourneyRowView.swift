//
//  JourneyRowView.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 12/07/2024.
//

import SwiftData
import SwiftUI

struct JourneyRowView<DataSource: JourneyRowDataSource>: View {
    @StateObject private var dataSource: DataSource

    init(dataSource: @autoclosure @escaping () -> DataSource) {
        self._dataSource = StateObject(wrappedValue: dataSource())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection
            Divider().padding(.horizontal, 14)
            contentSection

            if case .saved = dataSource.footer {
                Divider().padding(.horizontal, 14)
                footerSection
            }
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .contentShape(Rectangle())
        .listRowBackground(Color.clear)
        .listRowSeparator(.visible)
//        .padding(.horizontal, 4)
//        .padding(.vertical, 4)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 8) {
            CompanyLogo(dataSource.company, size: CGSize(width: 28, height: 28))
            Text("\(dataSource.company) \(dataSource.headsign)")
                .font(.subheadline)
                .fontWeight(.semibold)
            Spacer()
            HStack(spacing: 3) {
                Image(systemName: "clock")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(dataSource.duration)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Content

    private var contentSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(dataSource.primaryLeft)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .foregroundStyle(dataSource.primaryLeftColor)
                    .lineLimit(1)
                Text(dataSource.secondaryLeft)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(dataSource.primaryRight)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .foregroundStyle(dataSource.primaryRightColor)
                    .lineLimit(1)
                Text(dataSource.secondaryRight)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Footer (saved variant only)

    @ViewBuilder
    private var footerSection: some View {
        if case .saved(let date, let status) = dataSource.footer {
            HStack {
                Text(date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                JourneyStatusBadge(status: status)
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
    }
}

// MARK: - Convenience initializer for saved journeys

extension JourneyRowView where DataSource == SavedJourneyDataSource {
    init(journey: Journey) {
        self.init(dataSource: SavedJourneyDataSource(journey: journey))
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
