//
//  ClaimRegistry.swift
//  RailMapiOS
//
//  Routes a `Journey.company` value to the right `ClaimRules` implementation.
//  Unknown operators return `nil` — the UI falls back to a generic "no
//  refund flow available" state.
//

import Foundation

enum ClaimRegistry {
    /// Returns the rules for the given `Journey.company` string, matching
    /// case-insensitively against known brand keywords.
    ///
    /// Match priority matters: OUIGO must be matched **before** the broad
    /// "TGV / SNCF" fallback because OUIGO is operated by SNCF Voyageurs but
    /// has its own compensation schedule.
    static func rules(for company: String?) -> (any ClaimRules)? {
        guard let raw = company?.uppercased() else { return nil }

        switch raw {
        case let s where s.contains("OUIGO"):
            return OUIGORules.standard

        case let s where s.contains("INTERCITES") || s.contains("INTERCITÉS"):
            return SNCFG30Rules.intercites

        case let s where s.contains("TGV") || s.contains("INOUI") || s.contains("SNCF"):
            return SNCFG30Rules.tgv

        // Future operators wired in at this layer only — V1.x / V2:
        //   case let s where s.contains("EUROSTAR"): return EurostarRules.standard
        //   case let s where s.contains("LYRIA"): return SNCFG30InternationalRules.lyria
        //   case let s where s.contains("CFF") || s.contains("SBB"): return CFFRules.standard
        //   case let s where s.contains("DB") || s.contains("DEUTSCHE BAHN"): return DBRules.fernverkehr
        //   case let s where s.contains("TER"): return TERRegionalRules.fallback

        default:
            return nil
        }
    }
}
