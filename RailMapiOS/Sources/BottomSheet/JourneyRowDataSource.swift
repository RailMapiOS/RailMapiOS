//
//  JourneyRowDataSource.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 06/04/2026.
//

import SwiftUI

/// Abstraction for the data displayed in a `JourneyRowView`.
/// Allows the same row component to render both saved journeys and search results.
@MainActor
protocol JourneyRowDataSource: ObservableObject {
    var company: String { get }
    var headsign: String { get }
    var duration: String { get }

    /// Large text on the left (title2)
    var primaryLeft: String { get }
    var primaryLeftColor: Color { get }
    /// Caption text below primaryLeft
    var secondaryLeft: String { get }
    /// Large text on the right (title2)
    var primaryRight: String { get }
    var primaryRightColor: Color { get }
    /// Caption text below primaryRight
    var secondaryRight: String { get }

    /// The footer variant determines what appears at the bottom of the row.
    var footer: JourneyRowFooter { get }
}

enum JourneyRowFooter {
    case saved(date: String, status: JourneyStatus)
    case none
}
