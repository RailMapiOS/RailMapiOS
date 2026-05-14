//
//  SNCFG30Rules.swift
//  RailMapiOS
//
//  SNCF "Garantie 30 minutes" (G30) compensation tiers, applicable to TGV
//  INOUI, Intercités and OUIGO. TER has region-specific rules — handled by
//  separate ClaimRules implementations.
//
//  Reference: https://www.sncf-connect.com/aide/g30
//

import Foundation

/// Common base used by SNCF mainline operators (TGV INOUI, Intercités, OUIGO).
/// Thresholds are identical; we differentiate operators only on the displayed
/// contact info.
struct SNCFG30Rules: ClaimRules {
    let identifier: String
    let contact: OperatorContact

    func evaluate(delayMinutes: Int) -> ClaimEligibility? {
        switch delayMinutes {
        case 30..<60:
            return ClaimEligibility(percentage: 25, delayMinutes: delayMinutes, deadlineDays: 60)
        case 60..<180:
            return ClaimEligibility(percentage: 50, delayMinutes: delayMinutes, deadlineDays: 60)
        case 180...:
            return ClaimEligibility(percentage: 75, delayMinutes: delayMinutes, deadlineDays: 60)
        default:
            return nil
        }
    }

    // MARK: - Operator-specific contacts

    /// TGV INOUI / regular SNCF Voyageurs.
    static let tgv = SNCFG30Rules(
        identifier: "sncf-g30-tgv",
        contact: OperatorContact(
            displayName: "SNCF Voyageurs",
            phone: "3635",
            email: nil,
            twitterHandle: "SNCFVoyageurs",
            websiteURL: URL(string: "https://www.sncf-connect.com/aide"),
            refundFormURL: URL(string: "https://www.sncf-connect.com/app/account/refund"),
            refundFormRequiresLogin: true
        )
    )

    /// Intercités — same form, different brand contact.
    static let intercites = SNCFG30Rules(
        identifier: "sncf-g30-intercites",
        contact: OperatorContact(
            displayName: "Intercités",
            phone: "3635",
            email: nil,
            twitterHandle: "InOui_Officiel",
            websiteURL: URL(string: "https://www.intercites.sncf.com/aide"),
            refundFormURL: URL(string: "https://www.sncf-connect.com/app/account/refund"),
            refundFormRequiresLogin: true
        )
    )

    /// OUIGO — separate brand, separate refund flow.
    static let ouigo = SNCFG30Rules(
        identifier: "sncf-g30-ouigo",
        contact: OperatorContact(
            displayName: "OUIGO",
            phone: nil,
            email: "service.client@ouigo.com",
            twitterHandle: "OUIGOFrance",
            websiteURL: URL(string: "https://www.ouigo.com/aide"),
            refundFormURL: URL(string: "https://www.ouigo.com/aide/contactez-nous"),
            refundFormRequiresLogin: true
        )
    )
}
