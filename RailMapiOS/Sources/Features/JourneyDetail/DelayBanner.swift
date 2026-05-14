//
//  DelayBanner.swift
//  RailMapiOS
//
//  Live status header shown at the top of `JourneyDetailView` when the
//  realtime feed reports a delay or cancellation. Bold colored band — meant
//  to be impossible to miss, unlike the contact-style cards below.
//
//  Color contract — kept consistent with the row pastilles and the
//  product-wide convention:
//    - Orange = delayed (any positive arrival delay).
//    - Red    = cancelled (reserved exclusively for this state).
//
//  Informational only, *not* swipe-dismissable (unlike `RefundBanner`) — the
//  user cannot make a delay disappear, so the banner stays as long as the
//  realtime feed reports the issue.
//

import SwiftUI

/// Render-ready model: pre-built by the feature state so the View has nothing
/// to compute. `headline` is the main message, `alertMessage` is the
/// operator's GTFS-RT alert text (`AlertDTO.headerText` or descriptionText).
struct DelayInfo: Equatable {
    enum Kind: Equatable {
        /// Measured arrival delay in minutes.
        case delayed(minutes: Int)
        /// Trip cancelled.
        case cancelled
        /// Operator published a disruption alert without a specific measured
        /// delay (e.g. SNCF TER line-wide perturbation). Banner text comes
        /// from `alertMessage`.
        case disrupted
    }

    let kind: Kind
    /// First non-empty alert message from the operator, if published.
    let alertMessage: String?
}

struct DelayBanner: View {
    let info: DelayInfo

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.white.opacity(0.22))
                )

            VStack(alignment: .leading, spacing: 4) {
                headline
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    // Drop shadow keeps the headline readable when the
                    // material below desaturates the underlying color tint.
                    .shadow(color: .black.opacity(0.25), radius: 1, y: 1)

                if let alertMessage = info.alertMessage, !alertMessage.isEmpty {
                    Text(verbatim: alertMessage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.95))
                        .shadow(color: .black.opacity(0.25), radius: 1, y: 1)
                        .lineLimit(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        // Layered background:
        //   1. `.thinMaterial` base — gives the frosted-glass aesthetic that
        //      blends with the rest of the sheet (matches BookingCard etc.).
        //   2. `palette.gradient` overlay at high opacity — keeps the orange
        //      / red identity dominant so white text stays legible.
        //   3. A faint inner light strip on top via material at very low
        //      opacity adds the subtle "shine" expected of a material card.
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 18).fill(.thinMaterial)
                RoundedRectangle(cornerRadius: 18).fill(palette.gradient)
                    .opacity(0.92)
                RoundedRectangle(cornerRadius: 18).fill(.thinMaterial)
                    .opacity(0.08)
                    .allowsHitTesting(false)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(.white.opacity(0.18), lineWidth: 1)
        }
        .shadow(color: palette.opacity(0.25), radius: 6, y: 2)
    }

    // MARK: - Style derived from kind

    private var palette: Color {
        switch info.kind {
        case .delayed, .disrupted: return .orange
        case .cancelled:           return .red
        }
    }

    private var iconName: String {
        switch info.kind {
        case .delayed:    return "clock.badge.exclamationmark.fill"
        case .disrupted:  return "exclamationmark.triangle.fill"
        case .cancelled:  return "xmark.octagon.fill"
        }
    }

    /// The headline text uses LocalizedStringResource so the catalog picks up
    /// the keys at compile time.
    private var headline: Text {
        switch info.kind {
        case .delayed(let minutes):
            return Text("Delayed by \(formatDelay(minutes: minutes))")
        case .cancelled:
            return Text("Train cancelled")
        case .disrupted:
            return Text("Service disruption")
        }
    }

    /// Compact-then-readable: < 1h shows "45 min", ≥ 1h shows "1h25" / "1h".
    private func formatDelay(minutes: Int) -> String {
        if minutes < 60 { return "\(minutes) min" }
        let h = minutes / 60
        let m = minutes % 60
        return m == 0 ? "\(h)h" : "\(h)h\(String(format: "%02d", m))"
    }
}
