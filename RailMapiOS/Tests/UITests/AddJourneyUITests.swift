//
//  AddJourneyUITests.swift
//  RailMapiOSUITests
//
//  Created by Jérémie Patot on 23/02/2025.
//

import XCTest
import OHHTTPStubs
import OHHTTPStubsSwift

final class AddJourneyUITests: XCTestCase {
    
    let app = XCUIApplication()
    let searchText = "9706"


    override func setUpWithError() throws {
        super.setUp()
        continueAfterFailure = false
                
        app.launchArguments = ["UI_TEST", "STUB_NETWORK"]
        app.launch()
    }

    override func tearDownWithError() throws {
        HTTPStubs.removeAllStubs()
    }

    @MainActor
    func testCompleteJourneyFlow() throws {
        // 1. Accéder à l'écran d'ajout de trajet
        let bottomSheet = app.otherElements[AccessibilityID.BottomSheetView.navigationStack]
        XCTAssertTrue(bottomSheet.waitForExistence(timeout: 2))
        
        // 2. Accéder à l'écran de recherche
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 2))
        searchField.tap()
        searchField.typeText(searchText)
        
        // 3. Vérifier l'affichage des résultats de recherche
        let datePicker = app.otherElements[AccessibilityID.AddTicketView.datePicker]
        XCTAssertTrue(datePicker.waitForExistence(timeout: 5))
        
        // 4. Sélectionner une date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let testDate = formatter.string(from: Date())
        let dateRow = app.buttons[AccessibilityID.DatePickerView.dateRow(for: Date())]
        XCTAssertTrue(dateRow.waitForExistence(timeout: 2))
        dateRow.tap()
        
        // 5. Sélectionner les stations
        let stationList = app.tables[AccessibilityID.StationPickerView.list]
        XCTAssertTrue(stationList.waitForExistence(timeout: 3))
        
        // Sélection départ
        let firstStation = stationList.cells.element(boundBy: 0)
        firstStation.tap()
        
        // Sélection arrivée
        let lastStation = stationList.cells.element(boundBy: stationList.cells.count - 1)
        lastStation.tap()
        
        // Confirmer la sélection
        let confirmStationButton = app.buttons[AccessibilityID.StationPickerView.confirmButton]
        confirmStationButton.tap()
        
        // 6. Remplir les détails de confirmation
        let bookingCodeRow = app.otherElements[AccessibilityID.ConfirmationPickerView.bookingCodeRow]
        XCTAssertTrue(bookingCodeRow.waitForExistence(timeout: 2))
        bookingCodeRow.tap()
        
        let bookingCodeField = app.textFields["Code de réservation"]
        bookingCodeField.tap()
        bookingCodeField.typeText("ABC123")
        
        let seatRow = app.otherElements[AccessibilityID.ConfirmationPickerView.seatRow]
        seatRow.tap()
        
        let seatField = app.textFields["Numéro de siège"]
        seatField.tap()
        seatField.typeText("15A")
        
        // 7. Confirmer le trajet
        let confirmButton = app.buttons[AccessibilityID.ConfirmationPickerView.confirmButton]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 2))
        confirmButton.tap()
        
        // 8. Vérifier la confirmation finale
        let successMessage = app.staticTexts["Trajet ajouté avec succès"]
        XCTAssertTrue(successMessage.waitForExistence(timeout: 5))
    }

    func testNetworkErrorHandling() throws {
        // Réinitialiser les stubs
        HTTPStubs.removeAllStubs()
        
        // Configurer un stub d'erreur
        stub(condition: isMethodGET()) { _ in
            return HTTPStubsResponse(error: NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet))
        }
        
        // Relancer l'application avec la nouvelle configuration
        app.terminate()
        app.launch()
        
        // Tester le flux avec erreur réseau
        let searchField = app.searchFields[AccessibilityID.BottomSheetView.searchBar]
        XCTAssertTrue(searchField.waitForExistence(timeout: 2))
        searchField.tap()
        searchField.typeText(searchText)
        
        let errorMessage = app.staticTexts["Erreur de réseau"]
        XCTAssertTrue(errorMessage.waitForExistence(timeout: 5))
    }

//    private func stubNetworkRequests() {
//        // Stub pour la recherche de stations
//        stub(condition: isMethodGET() && pathStartsWith("/stops")) { _ in
//            guard let path = OHPathForFile("GET_stop_9706_SNCF_TGV.json", type(of: self)) else {
//                XCTFail("Fichier stub introuvable")
//                return HTTPStubsResponse(error: NSError(domain: "TEST", code: 500))
//            }
//            
//            return HTTPStubsResponse(
//                fileAtPath: path,
//                statusCode: 200,
//                headers: ["Content-Type": "application/json"]
//            )
//        }
//        
//        // Stub pour la création de trajet
//        stub(condition: isMethodPOST() && pathStartsWith("/journeys")) { _ in
//            return HTTPStubsResponse(
//                jsonObject: ["id": "12345", "status": "confirmed"],
//                statusCode: 201,
//                headers: ["Content-Type": "application/json"]
//            )
//        }
//        
//        // Stub pour les données météo
//        stub(condition: pathEndsWith("/weather")) { _ in
//            return HTTPStubsResponse(
//                jsonObject: ["temperature": 22, "condition": "sunny"],
//                statusCode: 200
//            )
//        }
//    }

}
