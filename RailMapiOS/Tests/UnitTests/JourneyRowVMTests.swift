//
//  JourneyRowVMTests.swift
//  RailMapiOSTests
//
//  Created by Jérémie Patot on 26/07/2024.
//

import CoreData
import XCTest
@testable import RailMapiOS

@MainActor
final class JourneyRowViewModelTests: XCTestCase {
    var journey: Journey!
    var viewModel: JourneyRowViewModel!
    var mockDateFormatterService: MockDateFormatterService!
    var mockJourneyDataService: MockJourneyDataService!
    
    @MainActor
    override func setUp() {
        super.setUp()
        
        let context = NSPersistentContainer.preview.viewContext
        journey = Journey(context: context)
        journey.headsign = "Test Train"
        journey.company = "Test Company"
        
        let departureStop = Stop(context: context)
        departureStop.status = "departure"
        let departureStopInfo = StopInfo(context: context)
        departureStopInfo.label = "Gare de TestVille"
        departureStop.stopinfo = departureStopInfo
        departureStop.departureTimeUTC = Date(timeIntervalSince1970: 16200) // 04:30 UTC
        journey.addToStops(departureStop)
        
        let arrivalStop = Stop(context: context)
        arrivalStop.status = "arrival"
        let arrivalStopInfo = StopInfo(context: context)
        arrivalStopInfo.label = "Gare de DestinationVille"
        arrivalStop.stopinfo = arrivalStopInfo
        arrivalStop.arrivalTimeUTC = Date(timeIntervalSince1970: 32400) // 09:00 UTC
        journey.addToStops(arrivalStop)
        
        journey.startDate = departureStop.departureTimeUTC
        journey.endDate = arrivalStop.arrivalTimeUTC
        
        mockDateFormatterService = MockDateFormatterService()
        mockJourneyDataService = MockJourneyDataService()
        
        // Configure les mocks
        mockDateFormatterService.formatJourneyTimeResult = "04:30"
        mockDateFormatterService.formatJourneyDateResult = "Thu. 01 Jan."
        mockDateFormatterService.calculateDurationResult = "04h30"
        
        mockJourneyDataService.departureStop = departureStop
        mockJourneyDataService.arrivalStop = arrivalStop
        
        viewModel = JourneyRowViewModel(
            journey: journey,
            dateFormatterService: mockDateFormatterService,
            journeyDataService: mockJourneyDataService
        )
    }
    
    @MainActor
    override func tearDown() {
        journey = nil
        viewModel = nil
        mockDateFormatterService = nil
        mockJourneyDataService = nil
        super.tearDown()
    }

    @MainActor
    func testHeadsign() {
        XCTAssertEqual(viewModel.headsign, "Test Train")
    }
    
    @MainActor
    func testDepartureTime() {
        XCTAssertEqual(viewModel.departureTime, "04:30")
        XCTAssertTrue(mockDateFormatterService.formatJourneyTimeCalled)
    }
    
    @MainActor
    func testDepartureDate() {
        XCTAssertEqual(viewModel.departureDate, "Thu. 01 Jan.")
        XCTAssertTrue(mockDateFormatterService.formatJourneyDateCalled)
    }
    
    @MainActor
    func testDepartureLabel() {
        XCTAssertEqual(viewModel.departureLabel, "Gare de TestVille")
        XCTAssertTrue(mockJourneyDataService.getDepartureStopCalled)
    }
    
    @MainActor
    func testArrivalTime() {
        XCTAssertEqual(viewModel.arrivalTime, "04:30") // Utilise la même valeur mock
        XCTAssertTrue(mockDateFormatterService.formatJourneyTimeCalled)
    }
    
    @MainActor
    func testArrivalDate() {
        XCTAssertEqual(viewModel.arrivalDate, "Thu. 01 Jan.") // Utilise la même valeur mock
        XCTAssertTrue(mockDateFormatterService.formatJourneyDateCalled)
    }
    
    @MainActor
    func testArrivalLabel() {
        XCTAssertEqual(viewModel.arrivalLabel, "Gare de DestinationVille")
        XCTAssertTrue(mockJourneyDataService.getArrivalStopCalled)
    }
    
    @MainActor
    func testCompany() {
        XCTAssertEqual(viewModel.compagny, "Test Company")
    }
    
    @MainActor
    func testDuration() {
        XCTAssertEqual(viewModel.duration, "04h30")
        XCTAssertTrue(mockDateFormatterService.calculateDurationCalled)
    }
}
