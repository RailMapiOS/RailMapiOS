//
//  JourneyDetailView.swift
//  RailMapiOS
//
//  Inspired by Flighty + Find My: flat layout, regularMaterial cards on a
//  neutral background, big readable times, and Find My-style info rows
//  (colored circular icon + label + trailing value).
//

import ComposableArchitecture
import SwiftUI

struct JourneyDetailView: View {
    @Bindable var store: StoreOf<JourneyDetailFeature>
    @State private var stopsExpanded = false

    // MARK: - Formatters

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    /// Extracts the city name from a SNCF-style station label.
    /// "Paris Gare de Lyon" → "Paris", "Toulouse Matabiau" → "Toulouse",
    /// "Aix-en-Provence TGV" → "Aix-en-Provence", "Le Mans" → "Le Mans".
    static func city(from label: String) -> String {
        let parts = label.split(separator: " ", omittingEmptySubsequences: true)
        guard let first = parts.first else { return label }
        let articles: Set<String> = ["La", "Le", "Les", "L'", "Saint", "Sainte", "St", "Ste"]
        if parts.count > 1, articles.contains(String(first)) {
            return "\(first) \(parts[1])"
        }
        return String(first)
    }

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE, dd MMM"
        return f
    }()

    // MARK: - Derived

    private var duration: String {
        guard let s = store.journey.startDate, let e = store.journey.endDate else { return "—" }
        let minutes = Int(e.timeIntervalSince(s) / 60)
        let h = minutes / 60
        let m = minutes % 60
        return h > 0 ? "\(h)h \(String(format: "%02d", m))" : "\(m) min"
    }

    private var statusText: String {
        let now = Date()
        guard let start = store.journey.startDate, let end = store.journey.endDate else { return "" }
        if now < start {
            let mins = Int(start.timeIntervalSince(now) / 60)
            if mins < 60 {
                return String(localized: "Departs in \(mins) min", comment: "Hero status when departure is less than an hour away.")
            }
            let h = mins / 60, m = mins % 60
            return String(localized: "Departs in \(h)h \(String(format: "%02d", m))", comment: "Hero status when departure is more than an hour away (h+m).")
        }
        if now < end {
            let mins = Int(end.timeIntervalSince(now) / 60)
            if mins < 60 {
                return String(localized: "Arrives in \(mins) min", comment: "Hero status when arrival is less than an hour away.")
            }
            let h = mins / 60, m = mins % 60
            return String(localized: "Arrives in \(h)h \(String(format: "%02d", m))", comment: "Hero status when arrival is more than an hour away (h+m).")
        }
        return String(localized: "Journey completed", comment: "Hero status after the journey's end date.")
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Live delay / cancellation banner — shown first, color-coded
                // per the realtime feed. Informational; not dismissable.
                if let delayInfo = store.delayInfo {
                    DelayBanner(info: delayInfo)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Refund eligibility banner — shown right under the delay
                // banner when the user's arrival delay crosses the operator's
                // compensation threshold (e.g. 30 min for SNCF G30).
                if let eligibility = store.claimEligibility,
                   let contact = store.operatorContact {
                    RefundBanner(
                        eligibility: eligibility,
                        operatorName: contact.displayName,
                        onTap: { store.send(.refundBannerTapped) },
                        onDismiss: { store.send(.refundBannerDismissed) }
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                heroCard
                tripCard
                bookingCard
                if store.stopsCount > 2 { stopsCard }

                // Operator contacts (Flighty-style) — always shown when we
                // know the operator, regardless of delay status.
                if let contact = store.operatorContact {
                    OperatorContactsCard(contact: contact)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        // Let the sheet's `.ultraThinMaterial` flow through — the regularMaterial
        // cards layer on top, matching the pattern used by SavedJourneyRow and
        // SearchResultRow elsewhere in the app.
        .scrollContentBackground(.hidden)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 10) {
                    CompanyLogo(store.journey.company, size: CGSize(width: 38, height: 38))
                    Text("\(Self.city(from: store.departureLabel)) → \(Self.city(from: store.arrivalLabel))")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                }
            }
        }
        .onAppear { store.send(.onAppear) }
        .onDisappear { store.send(.onDisappear) }
        .fullScreenCover(item: $store.scope(state: \.refundFlow, action: \.refundFlow)) { refundStore in
            RefundFlowView(store: refundStore)
        }
    }

    // MARK: - Hero card (departure → arrival)

    private var heroCard: some View {
        VStack(spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                stationColumn(
                    time: store.journey.startDate,
                    label: store.departureLabel,
                    alignment: .leading
                )
                Spacer(minLength: 8)
                durationColumn
                Spacer(minLength: 8)
                stationColumn(
                    time: store.journey.endDate,
                    label: store.arrivalLabel,
                    alignment: .trailing
                )
            }

            Divider()

            HStack(spacing: 8) {
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
                Text(statusText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                if let platform = store.realtimeStatus?.departurePlatform, !platform.isEmpty {
                    // Small chip — same color language as the platform pastilles
                    // in the row, kept compact so it doesn't dominate the card.
                    HStack(spacing: 3) {
                        Image(systemName: "rectangle.portrait.fill")
                            .font(.system(size: 9, weight: .bold))
                        Text("Platform \(platform)")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.blue.gradient, in: Capsule())
                }
                if let date = store.journey.startDate {
                    Text(Self.dayFormatter.string(from: date))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    private func stationColumn(time: Date?, label: String, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(time.map { Self.timeFormatter.string(from: $0) } ?? "—")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .monospacedDigit()
            Text(label)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(alignment == .trailing ? .trailing : .leading)
        }
        .frame(maxWidth: .infinity, alignment: alignment == .trailing ? .trailing : .leading)
    }

    private var durationColumn: some View {
        VStack(spacing: 4) {
            Image(systemName: "arrow.right")
                .font(.callout.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(duration)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 56)
    }

    // MARK: - Trip card (operator / train / date)

    private var tripCard: some View {
        cardSection(title: "Trip") {
            infoRow(icon: "tram.fill", color: .blue, label: "Operator",
                    valueText: Text(verbatim: store.journey.company ?? "—"))
            Divider().padding(.leading, 56).opacity(0.5)
            infoRow(icon: "number", color: .indigo, label: "Number",
                    valueText: Text(verbatim: store.journey.headsign ?? "—"))
            Divider().padding(.leading, 56).opacity(0.5)
            infoRow(icon: "calendar", color: .orange, label: "Date",
                    valueText: Text(verbatim: store.journey.startDate.map { Self.dayFormatter.string(from: $0) } ?? "—"))
        }
    }

    // MARK: - Booking card

    private var bookingCard: some View {
        cardSection(title: "Booking") {
            infoRow(icon: "ticket.fill", color: .pink, label: "Booking reference",
                    valueText: Text("Not provided"), valueDimmed: true)
            Divider().padding(.leading, 56).opacity(0.5)
            infoRow(icon: "carseat.right.fill", color: .teal, label: "Seat",
                    valueText: Text("Not provided"), valueDimmed: true)
        }
    }

    // MARK: - Stops card (expandable timeline)

    /// Stops ordered chronologically. We prefer `departureTimeUTC` (most stops
    /// have one); fall back to `arrivalTimeUTC` for the final destination.
    private var orderedStops: [Stop] {
        (store.journey.stops ?? [])
            .filter { ($0.departureTimeUTC ?? $0.arrivalTimeUTC) != nil }
            .sorted { lhs, rhs in
                let l = lhs.departureTimeUTC ?? lhs.arrivalTimeUTC ?? .distantPast
                let r = rhs.departureTimeUTC ?? rhs.arrivalTimeUTC ?? .distantPast
                return l < r
            }
    }

    private var stopsCard: some View {
        cardSection(title: "Itinerary") {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    stopsExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "point.topright.arrow.triangle.backward.to.point.bottomleft.scurvepath.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.green)
                        .frame(width: 30, height: 30)
                        .background(.green.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                    Text("Stops")
                        .font(.subheadline)
                    Spacer(minLength: 8)
                    Text("\(store.stopsCount)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(stopsExpanded ? 90 : 0))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if stopsExpanded {
                Divider().padding(.leading, 56).opacity(0.5)
                stopsTimeline
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var stopsTimeline: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(orderedStops.enumerated()), id: \.offset) { idx, stop in
                timelineRow(
                    stop: stop,
                    isFirst: idx == 0,
                    isLast: idx == orderedStops.count - 1
                )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private func timelineRow(stop: Stop, isFirst: Bool, isLast: Bool) -> some View {
        let time = stop.departureTimeUTC ?? stop.arrivalTimeUTC
        let label = stop.stopinfo?.label ?? "—"
        let isEndpoint = isFirst || isLast

        return HStack(alignment: .top, spacing: 12) {
            // Time column
            Text(time.map { Self.timeFormatter.string(from: $0) } ?? "—")
                .font(.subheadline)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 48, alignment: .leading)
                .padding(.top, 2)

            // Timeline gutter: vertical line + dot
            ZStack(alignment: .top) {
                // Line spans the full row height; trimmed at endpoints.
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 2)
                        .frame(maxWidth: .infinity)
                        .padding(.top, isFirst ? geo.size.height / 2 : 0)
                        .padding(.bottom, isLast ? geo.size.height / 2 : 0)
                }
                .frame(width: 12)

                Circle()
                    .fill(isEndpoint ? Color.accentColor : Color.secondary)
                    .frame(width: isEndpoint ? 10 : 7, height: isEndpoint ? 10 : 7)
                    .overlay(
                        Circle()
                            .stroke(Color.primary.opacity(0.05), lineWidth: 0.5)
                    )
                    .padding(.top, isEndpoint ? 5 : 7)
                    .frame(width: 12)
            }
            .frame(width: 12)

            // Station name — runtime data, never localized.
            Text(verbatim: label)
                .font(.subheadline)
                .fontWeight(isEndpoint ? .semibold : .regular)
                .foregroundStyle(isEndpoint ? .primary : .secondary)
                .lineLimit(2)
                .padding(.vertical, 2)
                .padding(.bottom, isLast ? 0 : 8)

            Spacer(minLength: 0)
        }
    }

    // MARK: - Reusable bits

    private func cardSection<Content: View>(title: LocalizedStringResource, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .padding(.leading, 6)
            VStack(spacing: 0) {
                content()
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        }
    }

    /// `label` is translatable copy; `valueText` is built by the caller — pass
    /// `Text("…")` for translatable values (auto-localized via the catalog) or
    /// `Text(verbatim: …)` for runtime data (operator name, headsign, dates).
    private func infoRow(icon: String, color: Color, label: LocalizedStringResource, valueText: Text, valueDimmed: Bool = false) -> some View {
        HStack(spacing: 12) {
            // Tinted icon — the colored chip pattern used elsewhere in the app
            // (e.g. AccountView's destructive row with `.red.opacity(0.1)`).
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 30, height: 30)
                .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
            Text(label)
                .font(.subheadline)
            Spacer(minLength: 8)
            valueText
                .font(.subheadline)
                .foregroundStyle(valueDimmed ? .secondary : .primary)
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }
}
