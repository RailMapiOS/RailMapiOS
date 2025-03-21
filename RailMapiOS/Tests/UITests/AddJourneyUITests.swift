//
//  AddJourneyUITests.swift
//  RailMapiOSUITests
//
//  Created by Jérémie Patot on 23/02/2025.
//

import XCTest

final class AddJourneyUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                Task {
                    await MainActor.run {
                        XCUIApplication().launch()
                    }
                }
            }
        }
    }
}
