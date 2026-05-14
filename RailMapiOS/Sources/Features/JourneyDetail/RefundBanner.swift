//
//  RefundBanner.swift
//  RailMapiOS
//
//  Eligibility banner shown under the journey header when the user's arrival
//  was delayed past the operator's compensation threshold (SNCF G30 etc.).
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
    let onTap: () -> Void
    let onDismiss: () -> Void

    /// Drag offset while the user is swiping. Negative = swiping left.
    @State private var dragOffset: CGFloat = 0

    /// Once dismissed, we collapse the banner with a fade+squeeze animation
    /// before the parent removes us from the layout.
    @State private var isDismissing: Bool = false

    /// Pixels at which a release commits the dismissal.
    private static let dismissThreshold: CGFloat = -120

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
                    Image(systemName: "eurosign.circle.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.green.gradient, in: RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Eligible for refund")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        Text(verbatim: eligibility.bannerLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
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
                        .strokeBorder(.green.opacity(0.5), lineWidth: 1)
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
            .accessibilityHint(Text("Opens the \(operatorName) refund form. Swipe left to dismiss."))
            .accessibilityAction(named: Text("Dismiss"), commitDismissal)
        }
        .scaleEffect(isDismissing ? 0.85 : 1, anchor: .trailing)
        .opacity(isDismissing ? 0 : 1)
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
