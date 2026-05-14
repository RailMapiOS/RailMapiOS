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

    // MARK: - SNCF G30 International (TGV Lyria, France-Italie/Espagne/Lux, DB-SNCF, SNCB, Fribourg)

    func test_SNCFG30Intl_underThirtyMinutes_noCompensation() {
        let rules = SNCFG30InternationalRules.lyria
        XCTAssertNil(rules.evaluate(delayMinutes: 0))
        XCTAssertNil(rules.evaluate(delayMinutes: 29))
    }

    func test_SNCFG30Intl_thirtyToTwoHours_givesTwentyFivePercent() {
        let rules = SNCFG30InternationalRules.lyria
        XCTAssertEqual(rules.evaluate(delayMinutes: 30)?.percentage, 25)
        XCTAssertEqual(rules.evaluate(delayMinutes: 90)?.percentage, 25)
        XCTAssertEqual(rules.evaluate(delayMinutes: 119)?.percentage, 25)
    }

    func test_SNCFG30Intl_twoHoursOrMore_givesFiftyPercent_andCapsThere() {
        let rules = SNCFG30InternationalRules.lyria
        XCTAssertEqual(rules.evaluate(delayMinutes: 120)?.percentage, 50)
        XCTAssertEqual(rules.evaluate(delayMinutes: 180)?.percentage, 50,
                       "International TGV caps at 50% — national G30 would give 75% here.")
        XCTAssertEqual(rules.evaluate(delayMinutes: 600)?.percentage, 50)
    }

    func test_SNCFG30Intl_allBrandsShareTheSameThresholds() {
        let brands: [any ClaimRules] = [
            SNCFG30InternationalRules.lyria,
            SNCFG30InternationalRules.franceItalie,
            SNCFG30InternationalRules.franceEspagne,
            SNCFG30InternationalRules.franceLuxembourg,
            SNCFG30InternationalRules.dbSncfCooperation,
            SNCFG30InternationalRules.bruxellesSNCB,
            SNCFG30InternationalRules.parisFribourg,
        ]
        let reference = SNCFG30InternationalRules.lyria
        for delay in [29, 30, 60, 119, 120, 240, 600] {
            let expected = reference.evaluate(delayMinutes: delay)?.percentage
            for brand in brands {
                XCTAssertEqual(brand.evaluate(delayMinutes: delay)?.percentage, expected,
                               "Brand \(brand.identifier) mismatches at \(delay) min")
            }
        }
    }

    // MARK: - Eurostar

    func test_Eurostar_underOneHour_noCompensation() {
        let rules = EurostarRules.standard
        XCTAssertNil(rules.evaluate(delayMinutes: 0))
        XCTAssertNil(rules.evaluate(delayMinutes: 30), "Eurostar does NOT compensate at 30 min.")
        XCTAssertNil(rules.evaluate(delayMinutes: 59))
    }

    func test_Eurostar_oneToTwoHours_givesTwentyFivePercent() {
        let rules = EurostarRules.standard
        XCTAssertEqual(rules.evaluate(delayMinutes: 60)?.percentage, 25)
        XCTAssertEqual(rules.evaluate(delayMinutes: 119)?.percentage, 25)
    }

    func test_Eurostar_twoHoursOrMore_givesFiftyPercent() {
        let rules = EurostarRules.standard
        XCTAssertEqual(rules.evaluate(delayMinutes: 120)?.percentage, 50)
        XCTAssertEqual(rules.evaluate(delayMinutes: 600)?.percentage, 50)
    }

    // MARK: - CFF (SBB / FFS)

    func test_CFF_underOneHour_noCompensation() {
        let rules = CFFRules.standard
        XCTAssertNil(rules.evaluate(delayMinutes: 0))
        XCTAssertNil(rules.evaluate(delayMinutes: 59))
    }

    func test_CFF_oneToTwoHours_givesTwentyFivePercent() {
        let rules = CFFRules.standard
        XCTAssertEqual(rules.evaluate(delayMinutes: 60)?.percentage, 25)
        XCTAssertEqual(rules.evaluate(delayMinutes: 119)?.percentage, 25)
    }

    func test_CFF_twoHoursOrMore_givesFiftyPercent() {
        let rules = CFFRules.standard
        XCTAssertEqual(rules.evaluate(delayMinutes: 120)?.percentage, 50)
        XCTAssertEqual(rules.evaluate(delayMinutes: 240)?.percentage, 50)
    }

    // MARK: - Deutsche Bahn (Fernverkehr)

    func test_DB_underOneHour_noCompensation() {
        let rules = DBRules.fernverkehr
        XCTAssertNil(rules.evaluate(delayMinutes: 0))
        XCTAssertNil(rules.evaluate(delayMinutes: 59))
    }

    func test_DB_oneToTwoHours_givesTwentyFivePercent() {
        let rules = DBRules.fernverkehr
        XCTAssertEqual(rules.evaluate(delayMinutes: 60)?.percentage, 25)
        XCTAssertEqual(rules.evaluate(delayMinutes: 119)?.percentage, 25)
    }

    func test_DB_twoHoursOrMore_givesFiftyPercent() {
        let rules = DBRules.fernverkehr
        XCTAssertEqual(rules.evaluate(delayMinutes: 120)?.percentage, 50)
        XCTAssertEqual(rules.evaluate(delayMinutes: 240)?.percentage, 50)
    }

    // MARK: - TER (regional stub)

    func test_TER_alwaysReturnsNil_evenForLargeDelays() {
        let rules = TERRegionalRules.fallback
        // No national grid → always nil. Banner is suppressed; the user
        // sees the regional contact card instead.
        for delay in [0, 30, 60, 120, 300] {
            XCTAssertNil(rules.evaluate(delayMinutes: delay),
                         "TER has no national schedule; should return nil at \(delay) min")
        }
    }

    func test_TER_contactPointsToRegionalPortal() {
        let contact = TERRegionalRules.fallback.contact
        XCTAssertNotNil(contact.websiteURL)
        XCTAssertTrue(contact.websiteURL?.absoluteString.contains("ter-transilien") ?? false)
    }

    // MARK: - All schedules: deadline = 90 days (EU Regulation 2021/782)

    func test_AllOperators_deadlineIsNinetyDays() {
        let operatorsAtSixtyMinDelay: [(String, ClaimEligibility?)] = [
            ("SNCF G30 TGV", SNCFG30Rules.tgv.evaluate(delayMinutes: 60)),
            ("SNCF G30 Intl Lyria", SNCFG30InternationalRules.lyria.evaluate(delayMinutes: 60)),
            ("OUIGO", OUIGORules.standard.evaluate(delayMinutes: 60)),
            ("Eurostar", EurostarRules.standard.evaluate(delayMinutes: 60)),
            ("CFF", CFFRules.standard.evaluate(delayMinutes: 60)),
            ("DB", DBRules.fernverkehr.evaluate(delayMinutes: 60)),
        ]
        for (label, eligibility) in operatorsAtSixtyMinDelay {
            XCTAssertEqual(eligibility?.deadlineDays, 90,
                           "Deadline must be 90 days (EU Reg 2021/782) for \(label)")
        }
    }

    // MARK: - ClaimRegistry routing (new operators)

    func test_ClaimRegistry_routesLyriaToInternational() {
        XCTAssertEqual(ClaimRegistry.rules(for: "TGV Lyria")?.identifier,
                       SNCFG30InternationalRules.lyria.identifier)
        XCTAssertEqual(ClaimRegistry.rules(for: "LYRIA")?.identifier,
                       SNCFG30InternationalRules.lyria.identifier)
    }

    func test_ClaimRegistry_routesFranceItalieToInternational() {
        XCTAssertEqual(ClaimRegistry.rules(for: "TGV France-Italie")?.identifier,
                       SNCFG30InternationalRules.franceItalie.identifier)
    }

    func test_ClaimRegistry_routesFranceEspagneToInternational() {
        XCTAssertEqual(ClaimRegistry.rules(for: "TGV France-Espagne")?.identifier,
                       SNCFG30InternationalRules.franceEspagne.identifier)
    }

    func test_ClaimRegistry_routesEurostar() {
        XCTAssertEqual(ClaimRegistry.rules(for: "Eurostar")?.identifier,
                       EurostarRules.standard.identifier)
        XCTAssertEqual(ClaimRegistry.rules(for: "EUROSTAR")?.identifier,
                       EurostarRules.standard.identifier)
    }

    func test_ClaimRegistry_routesCFF_SBB_FFS_toSameRules() {
        XCTAssertEqual(ClaimRegistry.rules(for: "CFF")?.identifier, CFFRules.standard.identifier)
        XCTAssertEqual(ClaimRegistry.rules(for: "SBB")?.identifier, CFFRules.standard.identifier)
        XCTAssertEqual(ClaimRegistry.rules(for: "FFS")?.identifier, CFFRules.standard.identifier)
    }

    func test_ClaimRegistry_routesDeutscheBahn() {
        XCTAssertEqual(ClaimRegistry.rules(for: "Deutsche Bahn")?.identifier,
                       DBRules.fernverkehr.identifier)
        XCTAssertEqual(ClaimRegistry.rules(for: "DB")?.identifier,
                       DBRules.fernverkehr.identifier)
    }

    func test_ClaimRegistry_routesTER() {
        XCTAssertEqual(ClaimRegistry.rules(for: "TER")?.identifier,
                       TERRegionalRules.fallback.identifier)
        XCTAssertEqual(ClaimRegistry.rules(for: "TER Bretagne")?.identifier,
                       TERRegionalRules.fallback.identifier)
    }

    func test_ClaimRegistry_priorityOrder_specificBrandsBeforeGenericTGV() {
        // "TGV Lyria" contains "TGV" but must match Lyria FIRST,
        // not the generic SNCF G30 fallback.
        XCTAssertEqual(ClaimRegistry.rules(for: "TGV Lyria")?.identifier,
                       SNCFG30InternationalRules.lyria.identifier,
                       "Lyria must beat the generic TGV fallback in match order.")
        // Same for OUIGO (no "TGV" in it, but a regression guard for the
        // SNCF-internal carve-out).
        XCTAssertEqual(ClaimRegistry.rules(for: "OUIGO TRAIN CLASSIQUE")?.identifier,
                       OUIGORules.standard.identifier)
    }

    // MARK: - ClaimEligibility metadata

    func test_ClaimEligibility_preservesMeasuredDelay() {
        let result = SNCFG30Rules.tgv.evaluate(delayMinutes: 73)
        XCTAssertEqual(result?.delayMinutes, 73)
        XCTAssertEqual(result?.percentage, 25)
    }
}
