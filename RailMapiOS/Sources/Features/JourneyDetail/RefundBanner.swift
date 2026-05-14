//
//  RefundBanner.swift
//  RailMapiOS
//
//  Eligibility banner shown under the journey header when the user's arrival
//  was delayed past the operator's compensation threshold (SNCF G30 etc.).
//
//  Two visual variants depending on the operator's process:
//
//  • Manual (default) — eg SNCF G30 / Intercités: the user must file a claim.
//    Banner is green + euro icon, CTA reads "Eligible for refund".
//    Tap → opens the operator's refund WebView with copy-paste chips.
//
//  • Automatic — eg OUIGO: the operator pushes the compensation by SMS
//    without any user action. Banner is blue + info icon, CTA reads
//    "Automatic compensation", and tapping opens a "follow-up" page (used
//    when the SMS never arrived after 15 days).
//
//  Interactions:
//    - Tap → opens the RefundFlow modal.
//    - Swipe-to-delete (drag trailing) → dismisses the banner permanently
//      for that journey via `onDismiss`. Mimics iOS notification dismissal.
//

import SwiftUI

struct RefundBanner: View {
    let eligibility: ClaimEligibility
    let operatorName: String

    /// `true` when the operator compensates automatically (OUIGO sends an
    /// SMS). Tweaks copy + colors so the user knows there's nothing to do
    /// unless the compensation never arrived.
    let isAutomaticCompensation: Bool

    let onTap: () -> Void
    let onDismiss: () -> Void

    /// Drag offset while the user is swiping. Negative = swiping left.
    @State private var dragOffset: CGFloat = 0

    /// Once dismissed, we collapse the banner with a fade+squeeze animation
    /// before the parent removes us from the layout.
    @State private var isDismissing: Bool = false

    /// Pixels at which a release commits the dismissal.
    private static let dismissThreshold: CGFloat = -120

    // MARK: - Convenience initializers

    /// Manual-claim banner (eg SNCF G30 / Intercités).
    init(
        eligibility: ClaimEligibility,
        operatorName: String,
        onTap: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.init(
            eligibility: eligibility,
            operatorName: operatorName,
            isAutomaticCompensation: false,
            onTap: onTap,
            onDismiss: onDismiss
        )
    }

    /// Full initializer (use when the operator may be automatic, eg OUIGO).
    init(
        eligibility: ClaimEligibility,
        operatorName: String,
        isAutomaticCompensation: Bool,
        onTap: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.eligibility = eligibility
        self.operatorName = operatorName
        self.isAutomaticCompensation = isAutomaticCompensation
        self.onTap = onTap
        self.onDismiss = onDismiss
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .trailing) {
            // Reveal layer behind the banner — visible only while swiping.
            HStack {
                Spacer()
                Image(systemName: "trash.fill")
                    .foregroundStyle(.white)
                    .padding(.trailing, 24)
            }
            .frame(maxHeight: .infinity)
            .background(.red, in: RoundedRectangle(cornerRadius: 18))
            .opacity(Double(min(1, abs(dragOffset) / 80)))

            // The banner itself.
            Button(action: onTap) {
                HStack(spacing: 12) {
                    Image(systemName: iconName)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(accentColor.gradient, in: RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(titleText)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        Text(verbatim: subtitleText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(accentColor.opacity(0.5), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
            .offset(x: dragOffset)
            .gesture(
                DragGesture(minimumDistance: 12, coordinateSpace: .local)
                    .onChanged { value in
                        // Only allow leftward drag; resist past-threshold (rubber band).
                        let raw = min(0, value.translation.width)
                        dragOffset = raw < Self.dismissThreshold
                            ? Self.dismissThreshold + (raw - Self.dismissThreshold) / 3
                            : raw
                    }
                    .onEnded { value in
                        if value.translation.width < Self.dismissThreshold {
                            commitDismissal()
                        } else {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                dragOffset = 0
                            }
                        }
                    }
            )
            .accessibilityHint(Text(accessibilityHintText))
            .accessibilityAction(named: Text("Dismiss"), commitDismissal)
        }
        .scaleEffect(isDismissing ? 0.85 : 1, anchor: .trailing)
        .opacity(isDismissing ? 0 : 1)
    }

    // MARK: - Variant-driven copy & style

    private var titleText: String {
        isAutomaticCompensation
            ? String(localized: "Automatic compensation",
                     comment: "Banner title when the operator (eg OUIGO) refunds without user action.")
            : String(localized: "Eligible for refund",
                     comment: "Banner title when the user must file a claim themselves.")
    }

    private var subtitleText: String {
        if isAutomaticCompensation {
            return String(
                localized: "\(eligibility.percentage)% sent by \(operatorName) — SMS within 15 days",
                comment: "Banner subtitle for automatic compensation. Two args: percentage, operator name."
            )
        }
        return eligibility.bannerLabel
    }

    private var iconName: String {
        isAutomaticCompensation ? "checkmark.seal.fill" : "eurosign.circle.fill"
    }

    private var accentColor: Color {
        isAutomaticCompensation ? .blue : .green
    }

    private var accessibilityHintText: String {
        isAutomaticCompensation
            ? String(localized: "Opens \(operatorName) follow-up if you didn't receive the SMS. Swipe left to dismiss.")
            : String(localized: "Opens the \(operatorName) refund form. Swipe left to dismiss.")
    }

    private func commitDismissal() {
        // Slide off the trailing edge, then fade — feels like a real swipe.
        withAnimation(.easeIn(duration: 0.2)) {
            dragOffset = -500
            isDismissing = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}
