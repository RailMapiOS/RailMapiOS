//
//  TERRegionalRules.swift
//  RailMapiOS
//
//  TER doesn't have a *national* compensation schedule — each French region
//  (Auvergne-Rhône-Alpes, Hauts-de-France, Occitanie, …) defines its own
//  thresholds and refund percentages. Rather than ship 13 unverified regional
//  schedules in V1, we expose this stub:
//
//  • `evaluate` always returns nil → no eligibility banner shown.
//  • The contact card surfaces the regional claim portal so the user can file
//    a claim themselves on the right SNCF Voyageurs subsite.
//
//  The user falls back to the manual flow ("contactez votre région"), which
//  is exactly what SNCF Connect tells people to do today.
//
//  V1.x improvement: ship a per-region overlay once we have a verified grid
//  (Île-de-France Mobilités garantie, TER Bretagne, TER Occitanie…).
//
//  Source: https://www.sncf-connect.com/aide/retard-de-votre-train-et-remboursement
//

import Foundation

struct TERRegionalRules: ClaimRules {
    let identifier: String
    let contact: OperatorContact

    /// TER has no national schedule we can apply uniformly — always nil for
    /// V1. Surface the contact card so the user can file a claim manually
    /// on their region's portal.
    func evaluate(delayMinutes: Int) -> ClaimEligibility? {
        return nil
    }

    /// Fallback TER ruleset — points to the general SNCF Voyageurs TER hub
    /// where the user picks their region.
    static let fallback = TERRegionalRules(
        identifier: "sncf-ter-regional-fallback",
        contact: OperatorContact(
            displayName: "TER",
            phone: nil,
            email: nil,
            twitterHandle: "SNCFVoyageurs",
            websiteURL: URL(string: "https://www.sncf-voyageurs.com/fr/contactez-nous/en-cas-de-retard/ter-transilien/"),
            refundFormURL: URL(string: "https://www.sncf-voyageurs.com/fr/contactez-nous/en-cas-de-retard/ter-transilien/"),
            refundFormRequiresLogin: false
        )
    )
}
