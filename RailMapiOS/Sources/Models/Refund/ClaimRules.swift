//
//  ClaimRules.swift
//  RailMapiOS
//
//  Per-operator delay-compensation rules. Each operator (SNCF, OUIGO, DB,
//  Renfe…) implements `ClaimRules` to translate a measured delay into a
//  compensation percentage. The shared `ClaimRegistry` routes by
//  `Journey.company`.
//

import Foundation

/// Result of evaluating a journey's delay against an operator's rules.
struct ClaimEligibility: Equatable, Sendable {
    /// Refund percentage of the ticket price (25 / 50 / 75 / 100…).
    let percentage: Int

    /// Measured arrival delay in minutes.
    let delayMinutes: Int

    /// How many days the user has from the journey date to file a claim.
    let deadlineDays: Int

    /// Display label shown in the banner — e.g. "25% refund · 38 min late".
    var bannerLabel: String {
        String(localized: "\(percentage)% refund · \(delayMinutes) min late",
               comment: "Refund banner subtitle: '<percentage>% refund · <delay> min late'.")
    }
}

/// Pure rules contract — one implementation per operator scheme.
protocol ClaimRules: Sendable {
    /// Identifier shown in logs and analytics ("sncf-g30", "db-fahrgastrechte"…).
    var identifier: String { get }

    /// Customer-facing contact info, including the refund form URL.
    var contact: OperatorContact { get }

    /// `true` when the operator compensates **automatically** (no claim form
    /// to fill — they push a voucher or wire transfer themselves). OUIGO is
    /// the canonical example: they send an SMS with the compensation amount
    /// once the delay is confirmed. In that case the UI surfaces an
    /// informational banner with a follow-up contact link rather than a
    /// "File a claim" CTA.
    var isAutomaticCompensation: Bool { get }

    /// Returns the eligibility tier matching `delayMinutes`, or nil if below
    /// the smallest threshold.
    func evaluate(delayMinutes: Int) -> ClaimEligibility?
}

extension ClaimRules {
    /// Default: the user must file a claim themselves.
    var isAutomaticCompensation: Bool { false }
}
