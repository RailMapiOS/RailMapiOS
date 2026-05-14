//
//  SNCFG30InternationalRules.swift
//  RailMapiOS
//
//  SNCF "Garantie 30 minutes" — International variant. Same 30-min start as
//  the national G30, but **caps at 50%** instead of 75% beyond 3h.
//
//  Applies to all SNCF-operated international TGV services:
//    - TGV Lyria (FR ↔ CH)
//    - TGV INOUI France ↔ Italie
//    - TGV INOUI France ↔ Espagne
//    - TGV INOUI France ↔ Luxembourg
//    - TGV INOUI France ↔ Fribourg en Brisgau
//    - DB-SNCF in cooperation (FR ↔ DE)
//    - TGV Bruxelles via SNCB cooperation
//
//  Source: https://www.sncf-connect.com/aide/retard-de-votre-train-et-remboursement
//
//  Bareme (TGV INOUI International):
//    < 30 min     → 0%
//    30 min–2h    → 25%
//    ≥ 2h         → 50%   ← cap (vs 75% on national G30)
//

import Foundation

struct SNCFG30InternationalRules: ClaimRules {
    let identifier: String
    let contact: OperatorContact

    func evaluate(delayMinutes: Int) -> ClaimEligibility? {
        // EU Regulation 2021/782, art. 19: 90 days to file a claim.
        let deadline = 90

        switch delayMinutes {
        case 30..<120:
            return ClaimEligibility(percentage: 25, delayMinutes: delayMinutes, deadlineDays: deadline)
        case 120...:
            return ClaimEligibility(percentage: 50, delayMinutes: delayMinutes, deadlineDays: deadline)
        default:
            return nil
        }
    }

    // MARK: - Per-brand presets

    /// Shared SNCF Voyageurs refund form — every SNCF-operated international
    /// service routes through the same form.
    private static let sncfForm = OperatorContact(
        displayName: "SNCF Voyageurs",
        phone: "3635",
        email: nil,
        twitterHandle: "SNCFVoyageurs",
        websiteURL: URL(string: "https://www.sncf-connect.com/aide/retard-de-votre-train-et-remboursement"),
        refundFormURL: URL(string: "https://www.sncf-voyageurs.com/fr/contactez-nous/demande-et-reclamation/?path=/TR&stepCode=TR_D1"),
        refundFormRequiresLogin: true
    )

    /// TGV Lyria — Paris ↔ Genève, Zürich, Bâle, Lausanne…
    static let lyria = SNCFG30InternationalRules(
        identifier: "sncf-g30-intl-lyria",
        contact: OperatorContact(
            displayName: "TGV Lyria",
            phone: sncfForm.phone,
            email: sncfForm.email,
            twitterHandle: "TGVLyria",
            websiteURL: URL(string: "https://www.tgv-lyria.com/fr/fr"),
            refundFormURL: sncfForm.refundFormURL,
            refundFormRequiresLogin: true
        )
    )

    /// TGV INOUI France ↔ Italie (Paris ↔ Milan, Turin…).
    static let franceItalie = SNCFG30InternationalRules(
        identifier: "sncf-g30-intl-france-italie",
        contact: OperatorContact(
            displayName: "TGV INOUI France-Italie",
            phone: sncfForm.phone,
            email: sncfForm.email,
            twitterHandle: sncfForm.twitterHandle,
            websiteURL: sncfForm.websiteURL,
            refundFormURL: sncfForm.refundFormURL,
            refundFormRequiresLogin: true
        )
    )

    /// TGV INOUI France ↔ Espagne (Paris/Lyon/Marseille ↔ Barcelone…).
    static let franceEspagne = SNCFG30InternationalRules(
        identifier: "sncf-g30-intl-france-espagne",
        contact: OperatorContact(
            displayName: "TGV INOUI France-Espagne",
            phone: sncfForm.phone,
            email: sncfForm.email,
            twitterHandle: sncfForm.twitterHandle,
            websiteURL: sncfForm.websiteURL,
            refundFormURL: sncfForm.refundFormURL,
            refundFormRequiresLogin: true
        )
    )

    /// TGV INOUI France ↔ Luxembourg.
    static let franceLuxembourg = SNCFG30InternationalRules(
        identifier: "sncf-g30-intl-france-luxembourg",
        contact: OperatorContact(
            displayName: "TGV INOUI France-Luxembourg",
            phone: sncfForm.phone,
            email: sncfForm.email,
            twitterHandle: sncfForm.twitterHandle,
            websiteURL: sncfForm.websiteURL,
            refundFormURL: sncfForm.refundFormURL,
            refundFormRequiresLogin: true
        )
    )

    /// DB-SNCF in cooperation (Paris ↔ Francfort, Stuttgart, Munich…).
    /// The bookings made on SNCF Connect route through SNCF's form even
    /// though DB co-operates the service.
    static let dbSncfCooperation = SNCFG30InternationalRules(
        identifier: "sncf-g30-intl-db-sncf",
        contact: OperatorContact(
            displayName: "DB-SNCF en coopération",
            phone: sncfForm.phone,
            email: sncfForm.email,
            twitterHandle: sncfForm.twitterHandle,
            websiteURL: sncfForm.websiteURL,
            refundFormURL: sncfForm.refundFormURL,
            refundFormRequiresLogin: true
        )
    )

    /// TGV Bruxelles in cooperation with SNCB (Paris ↔ Bruxelles via SNCB).
    static let bruxellesSNCB = SNCFG30InternationalRules(
        identifier: "sncf-g30-intl-bruxelles-sncb",
        contact: OperatorContact(
            displayName: "TGV Bruxelles (SNCB)",
            phone: sncfForm.phone,
            email: sncfForm.email,
            twitterHandle: sncfForm.twitterHandle,
            websiteURL: sncfForm.websiteURL,
            refundFormURL: sncfForm.refundFormURL,
            refundFormRequiresLogin: true
        )
    )

    /// TGV INOUI Paris ↔ Fribourg-en-Brisgau.
    static let parisFribourg = SNCFG30InternationalRules(
        identifier: "sncf-g30-intl-paris-fribourg",
        contact: OperatorContact(
            displayName: "TGV INOUI Paris-Fribourg",
            phone: sncfForm.phone,
            email: sncfForm.email,
            twitterHandle: sncfForm.twitterHandle,
            websiteURL: sncfForm.websiteURL,
            refundFormURL: sncfForm.refundFormURL,
            refundFormRequiresLogin: true
        )
    )
}
