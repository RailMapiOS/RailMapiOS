import XCTest
import SwiftUI
import CoreData
@testable import RailMapiOS

// MARK: - Mock Services

// MARK: - Mock VehicleJourneyService

public final class MockVehicleJourneyService: VehicleJourneyServiceProtocol, Sendable {
    public var fetchVehicleJourneysResult: [VehicleJourney] = []
    public var passageDaysResult: [String: [Date]] = [:]
    public var shouldThrowError = false
    
    public init() {}
    
    public func fetchVehicleJourneys(headsign: String) async throws -> [VehicleJourney] {
        if shouldThrowError {
            throw ServiceError.serverError(URLResponse())
        }
        return fetchVehicleJourneysResult
    }
    
    public func getPassageDays(from vehicleJourneys: [VehicleJourney]) -> [String: [Date]] {
        return passageDaysResult
    }
}

// MARK: - Mock JourneyDataService

public final class MockJourneyDataService: JourneyDataServiceProtocol {
    public var departureStop: Stop?
    public var arrivalStop: Stop?
    
    public init() {}
    
    public func getDepartureStop(_ journey: Journey) -> Stop? {
        departureStop
    }
    
    public func getArrivalStop(_ journey: Journey) -> Stop? {
        arrivalStop
    }
}

// MARK: - Mock DateFormatterService

public final class MockDateFormatterService: DateFormatterServiceProtocol {
    public var formatDateResult: String = ""
    public var formatDateLettreResult: String = ""
    public var formattedHourResult: String = ""
    
    public var formatJourneyDateResult: String = ""
    public var formatJourneyTimeResult: String = ""
    public var calculateDurationResult: String = ""

    public init() {}
    
    public func formatDate(_ date: Date) -> String {
         formatDateResult
    }
    
    public func formatDateLettre(_ dateString: String) -> String {
        formatDateLettreResult
    }

    public func formattedHour(from dateString: String) -> String {
        formattedHourResult
    }
    
    public func formatJourneyDate(_ date: Date?) -> String {
        formatJourneyDateResult
    }
    
    public func formatJourneyTime(_ date: Date?) -> String {
        formatJourneyTimeResult
    }
    
    public func calculateDuration(startDate: Date?, endDate: Date?) -> String {
        calculateDurationResult
    }
}

// MARK: - Mock StringParserService

public final class MockStringParserService: StringParserServiceProtocol {
    public var extractNameResult: String = ""

    public init() {}
    
    public func extractName(from input: String) -> String {
        extractNameResult
    }
}
