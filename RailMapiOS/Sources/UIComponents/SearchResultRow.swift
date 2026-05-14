//
//  SearchResultRow.swift
//  RailMapiOS
//
//  Flighty-inspired search result card.
//  Large origin → destination hierarchy, headsign in pill, next departure hint.
//

import SwiftUI

struct SearchResultRow: View {
    let result: SearchResult

    private static let timeFormatter = DateFormatterService()

    private var company: String {
        guard let stopID = result.representative.stopTimes.first?.stopPoint.id else { return "—" }
        let parts = stopID.components(separatedBy: " ")
        if parts.count > 1, let c = parts[1].components(separatedBy: "-").first { return c }
        return "—"
    }

    private var duration: String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HHmmss"
        guard let dep = timeFormatter.date(from: result.originTime),
              let arr = timeFormatter.date(from: result.destinationTime) else { return "—" }
        return Self.timeFormatter.calculateDuration(startDate: dep, endDate: arr)
    }

    private var nextDepartureLabel: String? {
        guard let date = result.nextDeparture else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE d MMM"
        formatter.locale = Locale.current
        return formatter.string(from: date).capitalized
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header: company + headsign
            HStack(spacing: 8) {
                CompanyLogo(company, size: CGSize(width: 26, height: 26))
                Text(result.headsign)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(duration)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.secondary.opacity(0.1), in: Capsule())
            }

            // Big origin → destination block (Flighty-style)
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Self.timeFormatter.formattedHour(from: result.originTime))
                        .font(.title).fontWeight(.bold)
                        .monospacedDigit()
                    Text(result.originName)
                        .font(.callout)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Image(systemName: "arrow.right")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 4) {
                    Text(Self.timeFormatter.formattedHour(from: result.destinationTime))
                        .font(.title).fontWeight(.bold)
                        .monospacedDigit()
                    Text(result.destinationName)
                        .font(.callout)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.trailing)
                }
            }

            // Footer: next departure hint
            if let nextDeparture = nextDepartureLabel {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text("Next: \(nextDeparture)")
                        .font(.caption)
                    Spacer()
                    Text("\(result.stopCount) stops")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .modifier(SearchResultBackground())
        .contentShape(Rectangle())
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
    }
}

private struct SearchResultBackground: ViewModifier {
    func body(content: Content) -> some View {
        content.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
    }
}
