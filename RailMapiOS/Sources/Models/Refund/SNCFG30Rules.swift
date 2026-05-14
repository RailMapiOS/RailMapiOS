//
//  SNCFG30Rules.swift
//  RailMapiOS
//
//  SNCF "Garantie 30 minutes" (G30) compensation tiers — applicable to TGV
//  INOUI nationaux and INTERCITÉS. Same thresholds for both; only the
//  displayed operator contact differs.
//
//  OUIGO has a *different* schedule (no compensation before 1h, max 50%) and
//  lives in `OUIGORules.swift`. TGV INOUI International caps at 50% and will
//  live in `SNCFG30InternationalRules.swift` (V1.x).
//
//  Source: https://www.sncf-connect.com/aide/retard-de-votre-train-et-remboursement
//
//  Bareme (TGV INOUI national + INTERCITÉS):
//    < 30 min   → 0%
//    30 min–2h  → 25%
//    2h–3h      → 50%
//    ≥ 3h       → 75%
//
//  Form of compensation:
//    30 min–1h  → bon d'achat
//    1h–3h+     → indemnité en numéraire (ou bon voyage si l'utilisateur accepte)
//

import Foundation

/// Common base used by SNCF mainline national operators (TGV INOUI national,
/// INTERCITÉS). Thresholds are identical; we differentiate operators only on
/// the displayed contact info.
struct SNCFG30Rules: ClaimRules {
    let identifier: String
    let contact: OperatorContact

    func evaluate(delayMinutes: Int) -> ClaimEligibility? {
        // Règlement UE 2021/782 (art. 19) = 90 jours pour soumettre la demande.
        let deadline = 90

        switch delayMinutes {
        case 30..<120:
            return ClaimEligibility(percentage: 25, delayMinutes: delayMinutes, deadlineDays: deadline)
        case 120..<180:
            return ClaimEligibility(percentage: 50, delayMinutes: delayMinutes, deadlineDays: deadline)
        case 180...:
            return ClaimEligibility(percentage: 75, delayMinutes: delayMinutes, deadlineDays: deadline)
        default:
            return nil
        }
    }

    // MARK: - Operator-specific contacts

    /// TGV INOUI national / regular SNCF Voyageurs.
    static let tgv = SNCFG30Rules(
        identifier: "sncf-g30-tgv",
        contact: OperatorContact(
            displayName: "SNCF Voyageurs",
            phone: "3635",
            email: nil,
            twitterHandle: "SNCFVoyageurs",
            websiteURL: URL(string: "https://www.sncf-connect.com/aide/retard-de-votre-train-et-remboursement"),
            refundFormURL: URL(string: "https://www.sncf-voyageurs.com/fr/contactez-nous/demande-et-reclamation/?path=/TR&stepCode=TR_D1"),
            refundFormRequiresLogin: true
        )
    )

    /// INTERCITÉS — same form, different brand contact.
    static let intercites = SNCFG30Rules(
        identifier: "sncf-g30-intercites",
        contact: OperatorContact(
            displayName: "INTERCITÉS",
            phone: "3635",
            email: nil,
            twitterHandle: "InOui_Officiel",
            websiteURL: URL(string: "https://www.sncf-connect.com/aide/retard-de-votre-train-et-remboursement"),
            refundFormURL: URL(string: "https://www.sncf-voyageurs.com/fr/contactez-nous/demande-et-reclamation/?path=/TR&stepCode=TR_D1"),
            refundFormRequiresLogin: true
        )
    )
}
