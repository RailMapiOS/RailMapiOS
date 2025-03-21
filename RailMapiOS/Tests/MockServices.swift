import XCTest
import SwiftUI
import CoreData
@testable import RailMapiOS

// MARK: - Mock Services

// MARK: - Mock VehicleJourneyService

class MockVehicleJourneyService: VehicleJourneyServiceProtocol {
    var fetchVehicleJourneysResult: [VehicleJourney] = []
    var passageDaysResult: [String: [Date]] = [:]
    var fetchVehicleJourneysCalled = false
    var getPassageDaysCalled = false
    var shouldThrowError = false
    
    func fetchVehicleJourneys(headsign: String) async throws -> [VehicleJourney] {
        fetchVehicleJourneysCalled = true
        if shouldThrowError {
            throw ServiceError.serverError(URLResponse())
        }
        return fetchVehicleJourneysResult
    }
    
    func getPassageDays(from vehicleJourneys: [VehicleJourney]) -> [String: [Date]] {
        getPassageDaysCalled = true
        return passageDaysResult
    }
}

// MARK: - Mock JourneyDataService

class MockJourneyDataService: JourneyDataServiceProtocol {
    var departureStop: Stop?
    var arrivalStop: Stop?
    var getDepartureStopCalled = false
    var getArrivalStopCalled = false
    
    func getDepartureStop(_ journey: Journey) -> Stop? {
        getDepartureStopCalled = true
        return departureStop
    }
    
    func getArrivalStop(_ journey: Journey) -> Stop? {
        getArrivalStopCalled = true
        return arrivalStop
    }
}

// MARK: - Mock DateFormatterService

public class MockDateFormatterService: DateFormatterServiceProtocol {

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

public class MockStringParserService: StringParserServiceProtocol {
    public var extractNameResult: String = ""
    public var extractNameCalled = false

    public func extractName(from input: String) -> String {
        extractNameCalled = true
        return extractNameResult
    }
}
