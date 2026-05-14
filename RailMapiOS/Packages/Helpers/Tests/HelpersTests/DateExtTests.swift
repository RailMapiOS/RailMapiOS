//
//  DateExtTests.swift
//  Helpers
//
//  Created by Jérémie Patot on 15/11/2024.
//


import XCTest
@testable import Helpers

class DateExtTests: XCTestCase {

    func testFormattedTime_withDefaultFormat() {
        // Arrange
        let now = Date()
        let expectedTime = DateFormatter.localizedString(from: now, dateStyle: .none, timeStyle: .short)
        
        // Act
        let formattedTime = now.formattedTime()
        
        // Assert
        XCTAssertEqual(formattedTime, expectedTime, "formattedTime should return the time in HH:mm format.")
    }
    
    func testFormattedTime_withCustomFormat() {
        // Arrange
        let now = Date()
        let expectedTime = DateFormatter.localizedString(from: now, dateStyle: .none, timeStyle: .short)
        
        // Act
        let formattedTime = now.formattedTime(with: "hh:mm a")
        
        // Assert
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        let expectedCustomTime = formatter.string(from: now)
        
        XCTAssertEqual(formattedTime, expectedCustomTime, "formattedTime should return the time using the custom format.")
    }

    func testTimeRemainingDescription_withFutureDate() {
        // Arrange
        let futureDate = Date().addingTimeInterval(3600)  // 1 heure dans le futur
        
        // Act
        let timeRemaining = futureDate.timeRemainingDescription()
        
        // Assert
        XCTAssertTrue(timeRemaining.contains("min"), "La description du temps restant devrait inclure 'min'.")
    }
    
    func testTimeRemainingDescription_withPastDate() {
        // Arrange
        let pastDate = Date().addingTimeInterval(-3600)  // 1 heure dans le passé
        
        // Act
        let timeRemaining = pastDate.timeRemainingDescription()
        
        // Assert
        // Looked up against the main bundle's String Catalog. In test (no bundle
        // override), the lookup returns the source-language English literal.
        XCTAssertEqual(timeRemaining, "Already departed", "timeRemainingDescription should return the 'Already departed' string for a past date.")
    }

    func testDuration_toFutureDate() {
        // Arrange
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(3660)  // 1 heure et 1 minute
        
        // Act
        let duration = startDate.duration(to: endDate)
        
        // Assert
        XCTAssertEqual(duration, "01h01", "Duration between the dates should be '01h01'.")
    }
    
    func testDuration_toPastDate() {
        // Arrange
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(-3660)  // 1 heure et 1 minute dans le passé
        
        // Act
        let duration = startDate.duration(to: endDate)
        
        // Assert
        XCTAssertEqual(duration, "00h00", "Duration between past dates should clamp to '00h00'.")
    }

    func testFormattedTimeRemaining() {
        // Arrange
        let timeInterval: TimeInterval = 3660 // 1 heure et 1 minute
        
        // Act
        let formattedTimeRemaining = timeInterval.formattedTimeRemaining()
        
        // Assert
        XCTAssertEqual(formattedTimeRemaining, "1 h 1 min", "formattedTimeRemaining should return '1 h 1 min'.")
    }
}
