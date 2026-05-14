//
//  CFFRules.swift
//  RailMapiOS
//
//  Swiss Federal Railways (CFF / SBB / FFS) compensation rules.
//
//  Specifics:
//    - Starts at 1h (NOT 30 min like SNCF G30).
//    - 90-day filing window.
//    - **Minimum payout of 5 CHF** — claims below that threshold aren't paid.
//      We don't enforce this in `evaluate` because we don't have ticket
//      price in `Journey`; the user will see the threshold on the CFF form.
//    - Cancellation gives right to a full refund (we don't model that here —
//      it's a separate UI flow tied to `RealtimeStatus.isCancelled`).
//
//  Source: https://www.sncf-connect.com/aide/retard-de-votre-train-et-remboursement
//  Claim form: https://www.sbb.ch/fr/aide-et-contact/service-clientele/critiques-compliments/reclamations.html
//
//  Bareme:
//    < 1h     → 0%
//    1h–2h    → 25%
//    ≥ 2h     → 50%
//

import Foundation

struct CFFRules: ClaimRules {
    let identifier: String
    let contact: OperatorContact

    func evaluate(delayMinutes: Int) -> ClaimEligibility? {
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

    /// Canonical CFF / SBB / FFS ruleset.
    static let standard = CFFRules(
        identifier: "cff-sbb-ffs",
        contact: OperatorContact(
            displayName: "CFF",
            phone: nil,
            email: nil,
            twitterHandle: "RailService",
            websiteURL: URL(string: "https://www.sbb.ch/fr"),
            refundFormURL: URL(string: "https://www.sbb.ch/fr/aide-et-contact/service-clientele/critiques-compliments/reclamations.html"),
            refundFormRequiresLogin: false
        )
    )
}
