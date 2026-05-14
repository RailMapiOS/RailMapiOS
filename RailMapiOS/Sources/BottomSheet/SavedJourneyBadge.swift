//
//  SavedJourneyBadge.swift
//  RailMapiOS
//
//  Realtime status pastilles overlaid on a `SavedJourneyRow`.
//  Color coding:
//    - Orange = delayed (any positive delay).
//    - Red    = cancelled (reserved exclusively for this state).
//

import SwiftUI

enum SavedJourneyBadge {
    /// Train is delayed by N minutes at the user's arrival.
    case delayed(minutes: Int)
    /// Train is cancelled. Red is *only* used for this case.
    case cancelled

    @ViewBuilder
    var view: some View {
        switch self {
        case .delayed(let minutes):
            HStack(spacing: 3) {
                Image(systemName: "clock.badge.exclamationmark.fill")
                    .font(.system(size: 10, weight: .bold))
                Text(verbatim: Self.formatDelay(minutes: minutes))
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(.orange.gradient, in: Capsule())
            .shadow(color: .black.opacity(0.15), radius: 2, y: 1)

        case .cancelled:
            HStack(spacing: 3) {
                Image(systemName: "xmark.octagon.fill")
                    .font(.system(size: 10, weight: .bold))
                Text("Cancelled")
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(.red.gradient, in: Capsule())
            .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
        }
    }

    /// Compact delay formatter. <60min → `+45m`, otherwise `+1h25`.
    private static func formatDelay(minutes: Int) -> String {
        if minutes < 60 { return "+\(minutes)m" }
        let h = minutes / 60
        let m = minutes % 60
        return m == 0 ? "+\(h)h" : "+\(h)h\(String(format: "%02d", m))"
    }
}
