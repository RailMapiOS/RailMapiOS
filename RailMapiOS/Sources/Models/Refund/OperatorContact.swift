//
//  OperatorContact.swift
//  RailMapiOS
//
//  Customer-facing contact handles for a rail operator: phone, email, X handle,
//  website, and the URL of the refund/claim form. Surfaced at the bottom of
//  the JourneyDetailView (Flighty-style) and tapped to open the right system
//  handler (`tel:`, `mailto:`, `x.com/...`, etc.).
//

import Foundation

struct OperatorContact: Equatable, Sendable {
    /// Human-readable operator name shown as the section header.
    let displayName: String

    /// Customer service phone number (E.164 or local format — both work with `tel:`).
    let phone: String?

    /// Customer service email.
    let email: String?

    /// X / Twitter handle (without leading `@`).
    let twitterHandle: String?

    /// General website (homepage or "Contact us" page).
    let websiteURL: URL?

    /// URL that opens the refund/claim form. Most operators require an
    /// authenticated session — see `refundFormRequiresLogin` to display the
    /// right hint to the user before launching the WebView.
    let refundFormURL: URL?

    /// `true` when the operator's refund form requires the user to be logged
    /// into their account first (almost always true). The flow opens a
    /// WebView; the user authenticates once, the cookie persists.
    let refundFormRequiresLogin: Bool
}
