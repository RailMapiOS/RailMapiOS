import XCTest
import SwiftUI
import CoreData
@testable import RailMap

class AddTicketVMTests: XCTestCase {
    var viewModel: AddTicketVM!
    var mockURLSession: MockURLSession!
    
    override func setUp() {
        super.setUp()
        viewModel = AddTicketVM()
        mockURLSession = MockURLSession()
    }
    
    override func tearDown() {
        viewModel = nil
        mockURLSession = nil
        super.tearDown()
    }
    
    // MARK: - Date Formatting Tests
    
    func testFormatDate() {
        // Given
        let dateComponents = DateComponents(year: 2023, month: 9, day: 14)
        let date = Calendar.current.date(from: dateComponents)!
        
        // When
        let formattedDate = viewModel.formatDate(date)
        
        // Then
        XCTAssertEqual(formattedDate, "14/09/23")
    }
    
    func testFormatDateLettre_ValidDate() {
        // Given
        let dateString = "14/09/2023"
        
        // When
        let formattedDate = viewModel.formatDateLettre(dateString)
        
        // Then
        XCTAssertEqual(formattedDate, "14 September")
    }
    
    func testFormatDateLettre_InvalidDate() {
        // Given
        let dateString = "invalid-date"
        
        // When
        let formattedDate = viewModel.formatDateLettre(dateString)
        
        // Then
        XCTAssertEqual(formattedDate, "N/A")
    }
    
    func testFormattedHour_ValidTime() {
        // Given
        let timeString = "123045"
        
        // When
        let formattedTime = viewModel.formattedHour(from: timeString)
        
        // Then
        XCTAssertEqual(formattedTime, "12:30")
    }
    
    func testFormattedHour_InvalidTime() {
        // Given
        let timeString = "invalid-time"
        
        // When
        let formattedTime = viewModel.formattedHour(from: timeString)
        
        // Then
        XCTAssertEqual(formattedTime, "Erreur, mauvais format de date")
    }
    
    // MARK: - Name Extraction Tests
    
    func testExtractName_ValidInput() {
        // Given
        let input = "trip:OCE TGV INOUI-12345"
        
        // When
        let extractedName = viewModel.extractName(from: input)
        
        // Then
        XCTAssertEqual(extractedName, "TGV INOUI")
    }
    
    func testExtractName_NoMatch() {
        // Given
        let input = "invalid-input"
        
        // When
        let extractedName = viewModel.extractName(from: input)
        
        // Then
        XCTAssertEqual(extractedName, "")
    }
    
    // MARK: - Passage Days Tests
    
    func testGetPassageDays_WithActivePeriods() {
        // Given
        let vehicleJourneys = createSampleVehicleJourneys()
        
        // When
        let passageDays = viewModel.getPassageDays(from: vehicleJourneys)
        
        // Then
        XCTAssertEqual(passageDays.count, 1)
        XCTAssertEqual(passageDays["journey1"]?.count, 2) // Monday and Tuesday in the test period
        
        // Verify the dates are correct
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let expectedDates = [
            dateFormatter.date(from: "2023-09-18")!, // Monday
            dateFormatter.date(from: "2023-09-19")!  // Tuesday
        ]
        
        for expectedDate in expectedDates {
            XCTAssertTrue(passageDays["journey1"]?.contains(where: { Calendar.current.isDate($0, inSameDayAs: expectedDate) }) ?? false)
        }
    }
    
    func testGetPassageDays_WithExceptions() {
        // Given
        let vehicleJourneys = createSampleVehicleJourneysWithExceptions()
        
        // When
        let passageDays = viewModel.getPassageDays(from: vehicleJourneys)
        
        // Then
        XCTAssertEqual(passageDays.count, 1)
        
        // The original period would have Monday and Tuesday (2 days)
        // We added Wednesday as an exception and removed Tuesday
        // So we should have Monday and Wednesday (2 days)
        XCTAssertEqual(passageDays["journey1"]?.count, 2)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let expectedDates = [
            dateFormatter.date(from: "2023-09-18")!, // Monday
            dateFormatter.date(from: "2023-09-20")!  // Wednesday (added exception)
        ]
        
        for expectedDate in expectedDates {
            XCTAssertTrue(passageDays["journey1"]?.contains(where: { Calendar.current.isDate($0, inSameDayAs: expectedDate) }) ?? false)
        }
        
        // Tuesday should be removed
        let tuesdayDate = dateFormatter.date(from: "2023-09-19")!
        XCTAssertFalse(passageDays["journey1"]?.contains(where: { Calendar.current.isDate($0, inSameDayAs: tuesdayDate) }) ?? true)
    }
    
    // MARK: - API Fetch Tests
    
    func testFetchHeadsignAddTicket_Success() async {
        // Given
        let mockData = createMockVehicleJourneysData()
        mockURLSession.mockData = mockData
        mockURLSession.mockResponse = HTTPURLResponse(url: URL(string: "http://example.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        // Replace the URLSession with our mock
        URLProtocolMock.mockURLSession = mockURLSession
        URLProtocol.registerClass(URLProtocolMock.self)
        
        // When
        await viewModel.fetchHeadsignAddTicket(headsign: "TGV")
        
        // Then
        XCTAssertEqual(viewModel.vehicleJourneys.count, 1)
        XCTAssertEqual(viewModel.vehicleJourneys.first?.id, "journey1")
        
        // Clean up
        URLProtocol.unregisterClass(URLProtocolMock.self)
    }
    
    func testFetchHeadsignAddTicket_ServerError() async {
        // Given
        mockURLSession.mockResponse = HTTPURLResponse(url: URL(string: "http://example.com")!, statusCode: 500, httpVersion: nil, headerFields: nil)
        
        // Replace the URLSession with our mock
        URLProtocolMock.mockURLSession = mockURLSession
        URLProtocol.registerClass(URLProtocolMock.self)
        
        // When
        await viewModel.fetchHeadsignAddTicket(headsign: "TGV")
        
        // Then
        XCTAssertEqual(viewModel.vehicleJourneys.count, 0)
        
        // Clean up
        URLProtocol.unregisterClass(URLProtocolMock.self)
    }
    
    // MARK: - Helper Methods
    
    private func createSampleVehicleJourneys() -> [VehicleJourney] {
        let weekPattern = WeekPattern(monday: true, tuesday: true, wednesday: false, thursday: false, friday: false, saturday: false, sunday: false)
        let activePeriod = ActivePeriod(begin: "2023-09-18", end: "2023-09-19")
        let calendar = VehicleCalendar(weekPattern: weekPattern, activePeriods: [activePeriod], exceptions: nil)
        let vehicleJourney = VehicleJourney(id: "journey1", name: "Test Journey", calendars: [calendar], stopTimes: [])
        
        return [vehicleJourney]
    }
    
    private func createSampleVehicleJourneysWithExceptions() -> [VehicleJourney] {
        let weekPattern = WeekPattern(monday: true, tuesday: true, wednesday: false, thursday: false, friday: false, saturday: false, sunday: false)
        let activePeriod = ActivePeriod(begin: "2023-09-18", end: "2023-09-19")
        
        // Add Wednesday as an exception, remove Tuesday
        let exceptions = [
            CalendarException(type: .add, datetime: "2023-09-20"),
            CalendarException(type: .remove, datetime: "2023-09-19")
        ]
        
        let calendar = VehicleCalendar(weekPattern: weekPattern, activePeriods: [activePeriod], exceptions: exceptions)
        let vehicleJourney = VehicleJourney(id: "journey1", name: "Test Journey", calendars: [calendar], stopTimes: [])
        
        return [vehicleJourney]
    }
    
    private func createMockVehicleJourneysData() -> Data {
        let vehicleJourneys = VehicleJourneys(vehicleJourneys: createSampleVehicleJourneys())
        return try! JSONEncoder().encode(vehicleJourneys)
    }
}

// MARK: - Mock Classes

class MockURLSession: URLSession {
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?
    
    override func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let error = mockError {
            throw error
        }
        
        return (mockData ?? Data(), mockResponse ?? URLResponse())
    }
}

class URLProtocolMock: URLProtocol {
    static var mockURLSession: MockURLSession?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let client = client else { return }
        
        if let mockURLSession = URLProtocolMock.mockURLSession {
            do {
                let (data, response) = try mockURLSession.data(for: request)
                client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client.urlProtocol(self, didLoad: data)
                client.urlProtocolDidFinishLoading(self)
            } catch {
                client.urlProtocol(self, didFailWithError: error)
            }
        }
    }
    
    override func stopLoading() {}
}

// MARK: - Model Extensions for Testing

// These extensions are needed to make the models conform to Encodable for testing
extension VehicleJourneys: Encodable {}
extension VehicleJourney: Encodable {}
extension VehicleCalendar: Encodable {}
extension WeekPattern: Encodable {}
extension ActivePeriod: Encodable {}
extension CalendarException: Encodable {}
extension CalendarException.ExceptionType: Encodable {}
