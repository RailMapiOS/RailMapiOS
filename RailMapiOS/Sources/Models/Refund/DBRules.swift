//
//  DBRules.swift
//  RailMapiOS
//
//  Deutsche Bahn (DB) Fernverkehr compensation rules.
//
//  Specifics:
//    - Starts at 1h (NOT 30 min like SNCF G30).
//    - 90-day filing window.
//    - **Minimum payout of 4 €** — claims below that threshold aren't paid.
//      We don't enforce this in `evaluate` because we don't have ticket price
//      in `Journey`; the user will see the threshold on the DB form.
//    - For round-trip tickets, the compensation is based on the one-way price
//      (or half the total if not explicitly priced).
//
//  Source: https://www.sncf-connect.com/aide/retard-de-votre-train-et-remboursement
//  Claim form: https://int.bahn.de/fr/aide/contact/formulaires
//
//  Bareme (DB Fernverkehr — long-distance ICE / IC / EC):
//    < 1h     → 0%
//    1h–2h    → 25%
//    ≥ 2h     → 50%
//

import Foundation

struct DBRules: ClaimRules {
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

    /// Deutsche Bahn long-distance services (ICE / IC / EC).
    static let fernverkehr = DBRules(
        identifier: "db-fernverkehr",
        contact: OperatorContact(
            displayName: "Deutsche Bahn",
            phone: nil,
            email: nil,
            twitterHandle: "DB_Bahn",
            websiteURL: URL(string: "https://www.bahn.de/"),
            refundFormURL: URL(string: "https://int.bahn.de/fr/aide/contact/formulaires"),
            refundFormRequiresLogin: false
        )
    )
}
