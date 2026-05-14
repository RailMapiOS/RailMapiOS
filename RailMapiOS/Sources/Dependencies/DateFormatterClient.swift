//
//  DateFormatterClient.swift
//  RailMapiOS
//
//  TCA Dependency wrapping DateFormatterService.
//

import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct DateFormatterClient {
    var formatJourneyTime: @Sendable (_ date: Date?) -> String = { _ in "" }
    var formatJourneyDate: @Sendable (_ date: Date?) -> String = { _ in "" }
    var calculateDuration: @Sendable (_ start: Date?, _ end: Date?) -> String = { _, _ in "" }
    var formattedHour: @Sendable (_ timeString: String) -> String = { _ in "" }
    var formatDate: @Sendable (_ date: Date) -> String = { _ in "" }
}

extension DateFormatterClient: DependencyKey {
    static let liveValue: Self = {
        let service = DateFormatterService()
        return Self(
            formatJourneyTime: { date in service.formatJourneyTime(date) },
            formatJourneyDate: { date in service.formatJourneyDate(date) },
            calculateDuration: { start, end in service.calculateDuration(startDate: start, endDate: end) },
            formattedHour: { timeString in service.formattedHour(from: timeString) },
            formatDate: { date in service.formatDate(date) }
        )
    }()
}

extension DependencyValues {
    var dateFormatterClient: DateFormatterClient {
        get { self[DateFormatterClient.self] }
        set { self[DateFormatterClient.self] = newValue }
    }
}
