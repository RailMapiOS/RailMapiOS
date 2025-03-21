import XCTest
import SwiftUI
import CoreData
@testable import RailMapiOS

// MARK: - Mock Services

// MARK: - Mock VehicleJourneyService

public final class MockVehicleJourneyService: VehicleJourneyServiceProtocol, @unchecked Sendable {
    public var fetchVehicleJourneysResult: [VehicleJourney] = []
    public var passageDaysResult: [String: [Date]] = [:]
    public var fetchVehicleJourneysCalled = false
    public var getPassageDaysCalled = false
    public var shouldThrowError = false
    
    public init() {}
    
    public func fetchVehicleJourneys(headsign: String) async throws -> [VehicleJourney] {
        fetchVehicleJourneysCalled = true
        if shouldThrowError {
            throw ServiceError.serverError(URLResponse())
        }
        return fetchVehicleJourneysResult
    }
    
    public nonisolated func getPassageDays(from vehicleJourneys: [VehicleJourney]) -> [String: [Date]] {
        getPassageDaysCalled = true
        return passageDaysResult
    }
}

// MARK: - Mock JourneyDataService

public final class MockJourneyDataService: JourneyDataServiceProtocol, @unchecked Sendable {
    public var departureStop: Stop?
    public var arrivalStop: Stop?
    public var getDepartureStopCalled = false
    public var getArrivalStopCalled = false
    
    public init() {}
    
    public func getDepartureStop(_ journey: Journey) -> Stop? {
        getDepartureStopCalled = true
        return departureStop
    }
    
    public func getArrivalStop(_ journey: Journey) -> Stop? {
        getArrivalStopCalled = true
        return arrivalStop
    }
}

// MARK: - Mock DateFormatterService

public final class MockDateFormatterService: DateFormatterServiceProtocol, @unchecked Sendable {
    public var formatDateResult: String = ""
    public var formatDateLettreResult: String = ""
    public var formattedHourResult: String = ""
    public var formatDateCalled = false
    public var formatDateLettreCalled = false
    public var formattedHourCalled = false
    
    public var formatJourneyDateResult: String = ""
    public var formatJourneyTimeResult: String = ""
    public var calculateDurationResult: String = ""
    public var formatJourneyDateCalled = false
    public var formatJourneyTimeCalled = false
    public var calculateDurationCalled = false

    public init() {}
    
    public func formatDate(_ date: Date) -> String {
        formatDateCalled = true
        return formatDateResult
    }
    
    public func formatDateLettre(_ dateString: String) -> String {
        formatDateLettreCalled = true
        return formatDateLettreResult
    }

    public func formattedHour(from dateString: String) -> String {
        formattedHourCalled = true
        return formattedHourResult
    }
    
    public func formatJourneyDate(_ date: Date?) -> String {
        formatJourneyDateCalled = true
        return formatJourneyDateResult
    }
    
    public func formatJourneyTime(_ date: Date?) -> String {
        formatJourneyTimeCalled = true
        return formatJourneyTimeResult
    }
    
    public func calculateDuration(startDate: Date?, endDate: Date?) -> String {
        calculateDurationCalled = true
        return calculateDurationResult
    }
}

// MARK: - Mock StringParserService

public final class MockStringParserService: StringParserServiceProtocol, @unchecked Sendable {
    public var extractNameResult: String = ""
    public var extractNameCalled = false

    public init() {}
    
    public func extractName(from input: String) -> String {
        extractNameCalled = true
        return extractNameResult
    }
}
