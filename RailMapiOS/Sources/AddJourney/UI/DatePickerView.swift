//
//  DatePickerView.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 17/01/2025.
//

import SwiftUI

struct DatePickerView: View {
    @EnvironmentObject var dataController: DataController

    @ObservedObject var viewModel: DatePickerViewModel
    @ObservedObject var router: Router

    var onNext: (DateRow) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text("Choose a date")
                .fontWeight(.bold)
                .font(.title3)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .accessibilityIdentifier(AccessibilityID.DatePickerView.title)

            List(viewModel.dateRows) { row in
                Button {
                    onNext(row)
                } label: {
                    HStack(spacing: 12) {
                        if let company = row.company {
                            Image("icon_\(company.lowercased())_minimal")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: 44)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.journey.headsign)
                                .font(.headline)
                            Text("Detected train journey")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(row.formattedDate)
                            .font(.title3)
                            .fontWeight(.medium)
                            .monospacedDigit()
                    }
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(AccessibilityID.DatePickerView.dateRow(for: row.date))
            }
            .accessibilityIdentifier(AccessibilityID.DatePickerView.title)
            .listStyle(.plain)
        }
    }
}
