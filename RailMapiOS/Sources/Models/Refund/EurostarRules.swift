//
//  EurostarRules.swift
//  RailMapiOS
//
//  Eurostar compensation rules — based on the EU Regulation 2021/782 baseline
//  that Eurostar applies to all its services (no operator-specific discount,
//  unlike SNCF G30 nationals).
//
//  Specifics:
//    - Starts at 1h (NOT 30 min like SNCF G30).
//    - 90-day filing window from the delay date.
//    - The refund form on eurostar.com asks for the **TCN number** (ticket
//      reference), which is *different* from the PNR booking code. The PNR
//      is what we know from SNCF Connect imports; the user has to fetch the
//      TCN from Eurostar's "Manage your booking" page.
//
//  Source: https://www.sncf-connect.com/aide/retard-de-votre-train-et-remboursement
//  Detailed schedule: https://www.eurostar.com/fr-fr/voyage/informations-trafic/politique-de-compensation
//
//  Bareme (V1 — EU Regulation 2021/782 baseline; revise once the detailed
//  Eurostar grid is needed):
//    < 1h     → 0%
//    1h–2h    → 25%
//    ≥ 2h     → 50%
//

import Foundation

struct EurostarRules: ClaimRules {
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

    /// Canonical Eurostar ruleset.
    /// Note: the user must retrieve the **TCN number** (not the PNR) from
    /// Eurostar's site before submitting — surfaced as a helper chip in the
    /// refund flow.
    static let standard = EurostarRules(
        identifier: "eurostar-eu2021",
        contact: OperatorContact(
            displayName: "Eurostar",
            phone: nil,
            email: nil,
            twitterHandle: "EurostarFR",
            websiteURL: URL(string: "https://help.eurostar.com/"),
            refundFormURL: URL(string: "https://www.eurostar.com/fr-fr/voyage/informations-trafic/politique-de-compensation"),
            refundFormRequiresLogin: false
        )
    )
}
