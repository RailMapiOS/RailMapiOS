//
//  OUIGORules.swift
//  RailMapiOS
//
//  OUIGO compensation rules — distinct from SNCF G30:
//  - No compensation under 1h of delay (G30 starts at 30 min).
//  - Max compensation capped at 50% (G30 nationals reach 75%).
//  - **Automatic**: OUIGO sends a confirmation SMS and pushes the compensation
//    themselves; the user has no form to fill. Our UI surfaces an informational
//    banner with a follow-up contact link (in case the SMS never arrives).
//
//  Source: https://www.sncf-connect.com/aide/retard-de-votre-train-et-remboursement
//
//  Bareme:
//    < 1h    → 0%
//    1h–2h   → 25%
//    ≥ 2h    → 50%
//

import Foundation

struct OUIGORules: ClaimRules {
    let identifier: String
    let contact: OperatorContact

    /// OUIGO compensates without any user action — we display an info banner
    /// rather than a "File a claim" CTA.
    var isAutomaticCompensation: Bool { true }

    func evaluate(delayMinutes: Int) -> ClaimEligibility? {
        // OUIGO follows EU Regulation 2021/782 — 90 days to follow up if the
        // SMS-pushed compensation never arrives.
        let deadline = 90

        switch delayMinutes {
        case 60..<120:
            return ClaimEligibility(percentage: 25, delayMinutes: delayMinutes, deadlineDays: deadline)
        case 120...:
            return ClaimEligibility(percentage: 50, delayMinutes: delayMinutes, deadlineDays: deadline)
        default:
            return nil
        }
    }

    /// Canonical OUIGO ruleset.
    /// The `refundFormURL` points to the customer-service contact page — used
    /// when the user reports they never received the SMS after 15 days.
    static let standard = OUIGORules(
        identifier: "ouigo-auto",
        contact: OperatorContact(
            displayName: "OUIGO",
            phone: nil,
            email: "service.client@ouigo.com",
            twitterHandle: "OUIGOFrance",
            websiteURL: URL(string: "https://www.ouigo.com/aide"),
            refundFormURL: URL(string: "https://www.ouigo.com/contact"),
            refundFormRequiresLogin: true
        )
    )
}
