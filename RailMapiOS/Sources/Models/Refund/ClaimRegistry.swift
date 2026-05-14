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
    static func rules(for company: String?) -> (any ClaimRules)? {
        guard let raw = company?.uppercased() else { return nil }

        switch raw {
        case let s where s.contains("OUIGO"):
            return SNCFG30Rules.ouigo

        case let s where s.contains("INTERCITES") || s.contains("INTERCITÉS"):
            return SNCFG30Rules.intercites

        case let s where s.contains("TGV") || s.contains("INOUI") || s.contains("SNCF"):
            return SNCFG30Rules.tgv

        // Future operators wired in at this layer only — V2/V3:
        //   case "DB": return DBFahrgastrechteRules.fernverkehr
        //   case let s where s.contains("RENFE"): return RenfeAVERules.ave
        //   case let s where s.contains("EUROSTAR"): return EurostarRules.standard

        default:
            return nil
        }
    }
}
