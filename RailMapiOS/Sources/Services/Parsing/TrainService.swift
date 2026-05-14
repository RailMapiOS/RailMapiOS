//
//  TrainService.swift
//  RailMapiOS
//
//  Identifies the rail service type recognized by the parser layer.
//  Maps to API source identifiers used by RailMapAPI.
//

import Foundation

enum TrainService: String, Sendable, Hashable, CaseIterable {
    // SNCF
    case sncfTGV
    case sncfTER
    case sncfIntercites
    case ouigo
    case eurostar

    // Deutsche Bahn
    case dbICE
    case dbIC
    case dbRE
    case dbRB

    // Other European operators
    case sbb
    case renfeAVE
    case renfeCercanias
    case sncb
    case trenitalia

    // UK
    case ukHeadcode

    // Generic / unknown
    case unknown

    /// Human-readable name shown in UI.
    var displayName: String {
        switch self {
        case .sncfTGV: return "SNCF TGV"
        case .sncfTER: return "SNCF TER"
        case .sncfIntercites: return "SNCF Intercités"
        case .ouigo: return "Ouigo"
        case .eurostar: return "Eurostar"
        case .dbICE: return "DB ICE"
        case .dbIC: return "DB IC/EC"
        case .dbRE: return "DB Regional Express"
        case .dbRB: return "DB Regionalbahn"
        case .sbb: return "SBB CFF FFS"
        case .renfeAVE: return "Renfe AVE"
        case .renfeCercanias: return "Renfe Cercanías"
        case .sncb: return "NMBS/SNCB"
        case .trenitalia: return "Trenitalia"
        case .ukHeadcode: return "UK Rail"
        case .unknown: return "Train"
        }
    }

    /// Identifier consumed by the RailMapAPI `?source=` query param.
    /// Returns nil for `.unknown` and `.ukHeadcode` (UK not yet wired in API).
    var apiSourceIdentifier: String? {
        switch self {
        case .sncfTGV: return "sncf-tgv"
        case .sncfTER: return "sncf-ter"
        case .sncfIntercites: return "sncf-intercites"
        case .ouigo: return "ouigo"
        case .eurostar: return "eurostar"
        case .dbICE, .dbIC, .dbRE, .dbRB: return "db"
        case .sbb: return "sbb"
        case .renfeAVE: return "renfe"
        case .renfeCercanias: return "renfe-cercanias"
        case .sncb: return "sncb"
        case .trenitalia: return "trenitalia-france"
        case .ukHeadcode, .unknown: return nil
        }
    }
}
