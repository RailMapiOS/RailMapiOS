//
//  SavedJourneyRow.swift
//  RailMapiOS
//
//  Flighty-inspired card for a saved journey.
//  Big origin → destination, prominent status pill, relative date.
//

import SwiftUI

struct SavedJourneyRow: View {
    let journey: Journey
    /// Optional live status: when present, drives the strikethrough+orange
    /// time variants and the cancellation styling. Pass nil for journeys we
    /// have no realtime data for — the row falls back to the scheduled time.
    var realtimeStatus: RealtimeStatus? = nil

    private static let formatter = DateFormatterService()
    private static let journeyData = JourneyDataService()

    // MARK: - Computed display values

    private var headsign: String { journey.headsign ?? "—" }
    private var company: String { journey.company ?? "—" }

    private var departureTime: String {
        Self.formatter.formatJourneyTime(journey.startDate)
    }

    private var arrivalTime: String {
        Self.formatter.formatJourneyTime(journey.endDate)
    }

    /// Delay applied to either side, in minutes. We only count positive
    /// values (early trains aren't a problem to surface).
    private var departureDelayMinutes: Int {
        guard let s = realtimeStatus?.departureDelaySeconds, s > 0 else { return 0 }
        return s / 60
    }

    private var arrivalDelayMinutes: Int {
        guard let s = realtimeStatus?.arrivalDelaySeconds, s > 0 else { return 0 }
        return s / 60
    }

    /// Pre-built `Text` for the departure column. Strikes the scheduled time
    /// and appends the delayed time in orange when there's a delay; renders
    /// the scheduled time alone otherwise.
    private var departureTimeText: Text {
        Self.timeText(scheduled: journey.startDate, delayMinutes: departureDelayMinutes)
    }

    private var arrivalTimeText: Text {
        Self.timeText(scheduled: journey.endDate, delayMinutes: arrivalDelayMinutes)
    }

    private static func timeText(scheduled: Date?, delayMinutes: Int) -> Text {
        let scheduledStr = formatter.formatJourneyTime(scheduled)
        guard delayMinutes > 0, let scheduled else {
            return Text(verbatim: scheduledStr)
        }
        let delayed = scheduled.addingTimeInterval(TimeInterval(delayMinutes * 60))
        let delayedStr = formatter.formatJourneyTime(delayed)
        return Text(verbatim: scheduledStr)
            .foregroundStyle(.secondary)
            .strikethrough(true, color: .secondary)
            + Text(" ")
            + Text(verbatim: delayedStr)
            .foregroundStyle(.orange)
    }

    private var departureLabel: String {
        Self.journeyData.getDepartureStop(journey)?.stopinfo?.label ?? "—"
    }

    private var arrivalLabel: String {
        Self.journeyData.getArrivalStop(journey)?.stopinfo?.label ?? "—"
    }

    private var duration: String {
        Self.formatter.calculateDuration(startDate: journey.startDate, endDate: journey.endDate)
    }

    private var status: JourneyStatus {
        SavedJourneyDataSource.deriveStatus(startDate: journey.startDate, endDate: journey.endDate)
    }

    /// Relative date: "Aujourd'hui", "Demain", "Hier", or "Lun 28 avr".
    private var relativeDate: String {
        guard let date = journey.startDate else { return "—" }
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Aujourd'hui" }
        if cal.isDateInTomorrow(date) { return "Demain" }
        if cal.isDateInYesterday(date) { return "Hier" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d MMM"
        formatter.locale = Locale.current
        return formatter.string(from: date).capitalized
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            originDestination
            footer
        }
        .padding(16)
        .modifier(SavedJourneyBackground())
        .contentShape(Rectangle())
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            CompanyLogo(company, size: CGSize(width: 26, height: 26))
            Text("\(company) \(headsign)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer()
            JourneyStatusBadge(status: status)
        }
    }

    // MARK: - Origin → Destination

    private var originDestination: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                departureTimeText
                    .font(.title).fontWeight(.bold)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(departureLabel)
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
                arrivalTimeText
                    .font(.title).fontWeight(.bold)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(arrivalLabel)
                    .font(.callout)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.trailing)
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 6) {
            Image(systemName: "calendar")
                .font(.caption2)
            Text(relativeDate)
                .font(.caption)
            Spacer()
            Image(systemName: "clock")
                .font(.caption2)
            Text(duration)
                .font(.caption)
        }
        .foregroundStyle(.secondary)
    }
}

// MARK: - Background

private struct SavedJourneyBackground: ViewModifier {
    func body(content: Content) -> some View {
        content.background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }
}
