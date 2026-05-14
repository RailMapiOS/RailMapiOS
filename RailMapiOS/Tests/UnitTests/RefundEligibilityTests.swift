//
//  RefundEligibilityTests.swift
//  RailMapiOSTests
//
//  Locks the SNCF / OUIGO refund schedules against the 2026 SNCF Connect
//  reference page. Any change to thresholds breaks these tests on purpose —
//  refund percentages are sensitive (user-facing legal info) and shouldn't
//  drift without an explicit decision.
//
//  Reference: https://www.sncf-connect.com/aide/retard-de-votre-train-et-remboursement
//

import XCTest
@testable import RailMapiOS

final class RefundEligibilityTests: XCTestCase {

    // MARK: - SNCF G30 (TGV INOUI national + INTERCITÉS)

    func test_SNCFG30_underThirtyMinutes_noCompensation() {
        let rules = SNCFG30Rules.tgv
        XCTAssertNil(rules.evaluate(delayMinutes: 0))
        XCTAssertNil(rules.evaluate(delayMinutes: 15))
        XCTAssertNil(rules.evaluate(delayMinutes: 29))
    }

    func test_SNCFG30_thirtyMinutesToTwoHours_givesTwentyFivePercent() {
        let rules = SNCFG30Rules.tgv
        XCTAssertEqual(rules.evaluate(delayMinutes: 30)?.percentage, 25)
        XCTAssertEqual(rules.evaluate(delayMinutes: 45)?.percentage, 25)
        XCTAssertEqual(rules.evaluate(delayMinutes: 60)?.percentage, 25, "Regression guard: 1h was wrongly 50% in V1.")
        XCTAssertEqual(rules.evaluate(delayMinutes: 90)?.percentage, 25)
        XCTAssertEqual(rules.evaluate(delayMinutes: 119)?.percentage, 25)
    }

    func test_SNCFG30_twoToThreeHours_givesFiftyPercent() {
        let rules = SNCFG30Rules.tgv
        XCTAssertEqual(rules.evaluate(delayMinutes: 120)?.percentage, 50)
        XCTAssertEqual(rules.evaluate(delayMinutes: 150)?.percentage, 50)
        XCTAssertEqual(rules.evaluate(delayMinutes: 179)?.percentage, 50)
    }

    func test_SNCFG30_threeHoursOrMore_givesSeventyFivePercent() {
        let rules = SNCFG30Rules.tgv
        XCTAssertEqual(rules.evaluate(delayMinutes: 180)?.percentage, 75)
        XCTAssertEqual(rules.evaluate(delayMinutes: 240)?.percentage, 75)
        XCTAssertEqual(rules.evaluate(delayMinutes: 600)?.percentage, 75)
    }

    func test_SNCFG30_INTERCITES_sharesTheSameThresholdsAsTGV() {
        let tgv = SNCFG30Rules.tgv
        let intercites = SNCFG30Rules.intercites
        for delay in [29, 30, 60, 119, 120, 179, 180, 240] {
            XCTAssertEqual(
                tgv.evaluate(delayMinutes: delay)?.percentage,
                intercites.evaluate(delayMinutes: delay)?.percentage,
                "Mismatch at \(delay) min between TGV national and INTERCITÉS"
            )
        }
    }

    func test_SNCFG30_deadlineIsNinetyDays_perEURegulation() {
        // EU Regulation 2021/782, art. 19: 90 days to file a claim.
        let rules = SNCFG30Rules.tgv
        XCTAssertEqual(rules.evaluate(delayMinutes: 60)?.deadlineDays, 90)
    }

    func test_SNCFG30_isNotAutomaticCompensation() {
        XCTAssertFalse(SNCFG30Rules.tgv.isAutomaticCompensation)
        XCTAssertFalse(SNCFG30Rules.intercites.isAutomaticCompensation)
    }

    // MARK: - OUIGO

    func test_OUIGO_underOneHour_noCompensation() {
        let rules = OUIGORules.standard
        XCTAssertNil(rules.evaluate(delayMinutes: 0))
        XCTAssertNil(rules.evaluate(delayMinutes: 30), "OUIGO does NOT compensate at 30 min (unlike G30).")
        XCTAssertNil(rules.evaluate(delayMinutes: 59))
    }

    func test_OUIGO_oneToTwoHours_givesTwentyFivePercent() {
        let rules = OUIGORules.standard
        XCTAssertEqual(rules.evaluate(delayMinutes: 60)?.percentage, 25)
        XCTAssertEqual(rules.evaluate(delayMinutes: 90)?.percentage, 25)
        XCTAssertEqual(rules.evaluate(delayMinutes: 119)?.percentage, 25)
    }

    func test_OUIGO_twoHoursOrMore_givesFiftyPercent() {
        let rules = OUIGORules.standard
        XCTAssertEqual(rules.evaluate(delayMinutes: 120)?.percentage, 50)
        XCTAssertEqual(rules.evaluate(delayMinutes: 240)?.percentage, 50)
        XCTAssertEqual(rules.evaluate(delayMinutes: 600)?.percentage, 50, "OUIGO caps at 50%, unlike SNCF G30 nationals (75%).")
    }

    func test_OUIGO_isAutomaticCompensation() {
        XCTAssertTrue(OUIGORules.standard.isAutomaticCompensation,
                      "OUIGO compensates automatically — UI must NOT prompt the user to file a claim.")
    }

    // MARK: - ClaimRegistry routing

    func test_ClaimRegistry_routesTGVtoSNCFG30() {
        XCTAssertEqual(ClaimRegistry.rules(for: "TGV INOUI")?.identifier, SNCFG30Rules.tgv.identifier)
        XCTAssertEqual(ClaimRegistry.rules(for: "tgv inoui")?.identifier, SNCFG30Rules.tgv.identifier)
        XCTAssertEqual(ClaimRegistry.rules(for: "SNCF")?.identifier, SNCFG30Rules.tgv.identifier)
    }

    func test_ClaimRegistry_routesIntercitesToSNCFG30Intercites() {
        XCTAssertEqual(ClaimRegistry.rules(for: "INTERCITES")?.identifier, SNCFG30Rules.intercites.identifier)
        XCTAssertEqual(ClaimRegistry.rules(for: "Intercités")?.identifier, SNCFG30Rules.intercites.identifier)
    }

    func test_ClaimRegistry_routesOUIGOtoOwnRules_notSNCFG30() {
        let rules = ClaimRegistry.rules(for: "OUIGO")
        XCTAssertEqual(rules?.identifier, OUIGORules.standard.identifier,
                       "OUIGO must NOT inherit SNCF G30 thresholds anymore.")
        XCTAssertTrue(rules?.isAutomaticCompensation ?? false)
    }

    func test_ClaimRegistry_returnsNilForUnknownCompany() {
        XCTAssertNil(ClaimRegistry.rules(for: nil))
        XCTAssertNil(ClaimRegistry.rules(for: ""))
        XCTAssertNil(ClaimRegistry.rules(for: "Random Bus Co"))
    }

    // MARK: - ClaimEligibility metadata

    func test_ClaimEligibility_preservesMeasuredDelay() {
        let result = SNCFG30Rules.tgv.evaluate(delayMinutes: 73)
        XCTAssertEqual(result?.delayMinutes, 73)
        XCTAssertEqual(result?.percentage, 25)
    }
}
