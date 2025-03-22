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
    var mockVehicleJourneyService: MockVehicleJourneyService = MockVehicleJourneyService()
    var mockDateFormatterService: MockDateFormatterService = MockDateFormatterService()
    var mockStringParserService: MockStringParserService = MockStringParserService()
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        viewModel = AddTicketVM(
            vehicleJourneyService: mockVehicleJourneyService,
            dateFormatterService: mockDateFormatterService,
            stringParserService: mockStringParserService
        )
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        try super.tearDownWithError()
    }
    
    func testFormatDate() throws {
        // Given
        let date = Date()
        let expectedResult = "14/09/23"
        mockDateFormatterService.formatDateResult = expectedResult
        
        // When
        let result = viewModel.formatDate(date)
        
        // Then
        XCTAssertEqual(result, expectedResult)
    }
    
    func testFetchHeadsignAddTicket_Success() async throws {
        // Given
        let expectedJourneys = [createSampleVehicleJourney()]
        mockVehicleJourneyService.fetchVehicleJourneysResult = expectedJourneys
        
        // When
        await viewModel.fetchHeadsignAddTicket(headsign: "TGV")
        
        // Then
        XCTAssertEqual(viewModel.vehicleJourneys.count, 1)
        XCTAssertEqual(viewModel.vehicleJourneys.first?.id, "journey1")
    }
    
    func testFetchHeadsignAddTicket_Failure() async throws {
        // Given
        mockVehicleJourneyService.shouldThrowError = true
        
        // When
        await viewModel.fetchHeadsignAddTicket(headsign: "TGV")
        
        // Then
        XCTAssertEqual(viewModel.vehicleJourneys.count, 0)
    }
    
    // MARK: - Helper Methods
    
    private func createSampleVehicleJourney() -> VehicleJourney {
        // No changes needed here
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
