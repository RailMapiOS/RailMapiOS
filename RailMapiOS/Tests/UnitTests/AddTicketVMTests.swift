//
//  AddTicketVMTests.swift
//  RailMapiOSTests
//
//  Created by Jérémie Patot on 26/07/2024.
//

import XCTest
import SwiftUI
import CoreData
@testable import RailMapiOS

@MainActor
final class AddTicketVMTests: XCTestCase {
    var viewModel: AddTicketVM!
    var mockVehicleJourneyService: MockVehicleJourneyService!
    var mockDateFormatterService: MockDateFormatterService!
    var mockStringParserService: MockStringParserService!
    
    override nonisolated func setUp() async throws {
        await MainActor.run {
            mockVehicleJourneyService = MockVehicleJourneyService()
            mockDateFormatterService = MockDateFormatterService()
            mockStringParserService = MockStringParserService()
            
            viewModel = AddTicketVM(
                vehicleJourneyService: mockVehicleJourneyService,
                dateFormatterService: mockDateFormatterService,
                stringParserService: mockStringParserService
            )
        }
        try await super.setUp()
    }

    override nonisolated func tearDown() async throws {
        try await super.tearDown()
        await MainActor.run {
            viewModel = nil
            mockVehicleJourneyService = nil
            mockDateFormatterService = nil
            mockStringParserService = nil
        }
    }
    
    // MARK: - Date Formatting Tests
    
    func testFormatDate() {
        // Given
        let date = Date()
        let expectedResult = "14/09/23"
        mockDateFormatterService.formatDateResult = expectedResult
        
        // When
        let result = viewModel.formatDate(date)
        
        // Then
        XCTAssertEqual(result, expectedResult)
        XCTAssertTrue(mockDateFormatterService.formatDateCalled)
    }
    
    func testFormatDateLettre() {
        // Given
        let dateString = "14/09/2023"
        let expectedResult = "14 September"
        mockDateFormatterService.formatDateLettreResult = expectedResult
        
        // When
        let result = viewModel.formatDateLettre(dateString)
        
        // Then
        XCTAssertEqual(result, expectedResult)
        XCTAssertTrue(mockDateFormatterService.formatDateLettreCalled)
    }
    
    func testFormattedHour() {
        // Given
        let timeString = "123045"
        let expectedResult = "12:30"
        mockDateFormatterService.formattedHourResult = expectedResult
        
        // When
        let result = viewModel.formattedHour(from: timeString)
        
        // Then
        XCTAssertEqual(result, expectedResult)
        XCTAssertTrue(mockDateFormatterService.formattedHourCalled)
    }
    
    // MARK: - Name Extraction Tests
    
    func testExtractName() {
        // Given
        let input = "trip:OCE TGV INOUI-12345"
        let expectedResult = "TGV INOUI"
        mockStringParserService.extractNameResult = expectedResult
        
        // When
        let result = viewModel.extractName(from: input)
        
        // Then
        XCTAssertEqual(result, expectedResult)
        XCTAssertTrue(mockStringParserService.extractNameCalled)
    }
    
    // MARK: - Passage Days Tests
    
    func testGetPassageDays() {
        // Given
        let vehicleJourneys = [createSampleVehicleJourney()]
        let expectedResult: [String: [Date]] = ["journey1": [Date()]]
        mockVehicleJourneyService.passageDaysResult = expectedResult
        
        // When
        let result = viewModel.getPassageDays(from: vehicleJourneys)
        
        // Then
        XCTAssertEqual(result.keys, expectedResult.keys)
        XCTAssertTrue(mockVehicleJourneyService.getPassageDaysCalled)
    }
    
    // MARK: - API Fetch Tests
    
    func testFetchHeadsignAddTicket_Success() async {
        // Given
        let expectedJourneys = [createSampleVehicleJourney()]
        mockVehicleJourneyService.fetchVehicleJourneysResult = expectedJourneys
        
        // When
        await viewModel.fetchHeadsignAddTicket(headsign: "TGV")
        
        // Then
        XCTAssertEqual(viewModel.vehicleJourneys.count, 1)
        XCTAssertEqual(viewModel.vehicleJourneys.first?.id, "journey1")
        XCTAssertTrue(mockVehicleJourneyService.fetchVehicleJourneysCalled)
    }
    
    func testFetchHeadsignAddTicket_Failure() async {
        // Given
        mockVehicleJourneyService.shouldThrowError = true
        
        // When
        await viewModel.fetchHeadsignAddTicket(headsign: "TGV")
        
        // Then
        XCTAssertEqual(viewModel.vehicleJourneys.count, 0)
        XCTAssertTrue(mockVehicleJourneyService.fetchVehicleJourneysCalled)
    }
    
    // MARK: - Helper Methods
    
    private func createSampleVehicleJourney() -> VehicleJourney {
        let weekPattern = WeekPattern(monday: true, tuesday: true, wednesday: false, thursday: false, friday: false, saturday: false, sunday: false)
        let activePeriod = ActivePeriod(begin: "2023-09-18", end: "2023-09-19")
        let calendar = VehicleCalendar(weekPattern: weekPattern, exceptions: nil, activePeriods: [activePeriod])
        
        return VehicleJourney(
            id: "journey1",
            name: "Test Journey",
            journeyPattern: JourneyPattern(id: "pattern1", name: "Test Pattern"),
            stopTimes: [],
            codes: [],
            validityPattern: ValidityPattern(beginningDate: "2023-09-18", days: ""),
            calendars: [calendar],
            trip: JourneyPattern(id: "trip1", name: "Test Trip"),
            disruptions: [],
            headsign: "TGV TEST"
        )
    }
}
