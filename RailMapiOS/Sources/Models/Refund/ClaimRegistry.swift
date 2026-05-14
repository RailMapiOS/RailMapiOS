//
//  ClaimRegistry.swift
//  RailMapiOS
//
//  Routes a `Journey.company` value to the right `ClaimRules` implementation.
//  Unknown operators return `nil` — the UI falls back to a generic "no
//  refund flow available" state.
//
//  Match priority matters — specific brands must be matched **before** broad
//  fallbacks. Notably:
//    - OUIGO before "SNCF" (OUIGO is operated by SNCF Voyageurs but has its
//      own automatic schedule).
//    - International TGV brands (Lyria, France-Italie…) before generic "TGV".
//    - Eurostar / CFF / DB before any SNCF match.
//

import Foundation

enum ClaimRegistry {
    /// Returns the rules for the given `Journey.company` string, matching
    /// case-insensitively against known brand keywords.
    static func rules(for company: String?) -> (any ClaimRules)? {
        guard let raw = company?.uppercased() else { return nil }

        switch raw {

        // MARK: SNCF brand-internal carve-outs (must be matched first)

        case let s where s.contains("OUIGO"):
            return OUIGORules.standard

        case let s where s.contains("INTERCITES") || s.contains("INTERCITÉS"):
            return SNCFG30Rules.intercites

        // MARK: SNCF International (matched before generic TGV/SNCF)

        case let s where s.contains("LYRIA"):
            return SNCFG30InternationalRules.lyria

        case let s where s.contains("FRANCE-ITALIE") || s.contains("FRANCE ITALIE"):
            return SNCFG30InternationalRules.franceItalie

        case let s where s.contains("FRANCE-ESPAGNE") || s.contains("FRANCE ESPAGNE"):
            return SNCFG30InternationalRules.franceEspagne

        case let s where s.contains("FRANCE-LUXEMBOURG") || s.contains("FRANCE LUXEMBOURG"):
            return SNCFG30InternationalRules.franceLuxembourg

        case let s where s.contains("FRIBOURG"):
            return SNCFG30InternationalRules.parisFribourg

        case let s where s.contains("DB-SNCF") || s.contains("SNCF-DB"):
            return SNCFG30InternationalRules.dbSncfCooperation

        case let s where s.contains("BRUXELLES") || s.contains("SNCB"):
            return SNCFG30InternationalRules.bruxellesSNCB

        // MARK: Foreign operators

        case let s where s.contains("EUROSTAR"):
            return EurostarRules.standard

        case let s where s.contains("DEUTSCHE BAHN") || s == "DB" || s.hasPrefix("DB "):
            return DBRules.fernverkehr

        case let s where s.contains("CFF") || s.contains("SBB") || s.contains("FFS"):
            return CFFRules.standard

        // MARK: SNCF generic fallbacks (TER first — regional, no national grid)

        case let s where s.contains("TER"):
            return TERRegionalRules.fallback

        case let s where s.contains("TGV") || s.contains("INOUI") || s.contains("SNCF"):
            return SNCFG30Rules.tgv

        default:
            return nil
        }
    }
}
