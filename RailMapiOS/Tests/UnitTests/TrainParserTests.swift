//
//  TrainParserTests.swift
//  RailMapiOSTests
//

import XCTest
@testable import RailMapiOS

final class TrainParserTests: XCTestCase {

    // MARK: - Normalization

    func test_normalize_trimsAndUppercases() {
        XCTAssertEqual(CompositeTrainParser.normalize("  tgv 6123 "), "TGV6123")
        XCTAssertEqual(CompositeTrainParser.normalize("ice  74"), "ICE74")
        XCTAssertEqual(CompositeTrainParser.normalize("1a23"), "1A23")
        XCTAssertEqual(CompositeTrainParser.normalize(""), "")
    }

    // MARK: - SNCF Parser

    func test_sncf_parsesTGV() {
        let parser = SNCFTrainParser()
        let result = parser.parse("TGV6123")
        XCTAssertEqual(result?.service, .sncfTGV)
        XCTAssertEqual(result?.prefix, "TGV")
        XCTAssertEqual(result?.number, "6123")
    }

    func test_sncf_parsesTER() {
        let parser = SNCFTrainParser()
        let result = parser.parse("TER84321")
        XCTAssertEqual(result?.service, .sncfTER)
        XCTAssertEqual(result?.number, "84321")
    }

    func test_sncf_parsesIntercitesShortAndLong() {
        let parser = SNCFTrainParser()
        XCTAssertEqual(parser.parse("IC2045")?.service, .sncfIntercites)
        XCTAssertEqual(parser.parse("INTERCITE3941")?.service, .sncfIntercites)
        XCTAssertEqual(parser.parse("INTERCITES3941")?.service, .sncfIntercites)
    }

    func test_sncf_parsesOuigoAndEurostar() {
        let parser = SNCFTrainParser()
        XCTAssertEqual(parser.parse("OUIGO7634")?.service, .ouigo)
        XCTAssertEqual(parser.parse("EUROSTAR9114")?.service, .eurostar)
    }

    func test_sncf_rejectsUnknownPrefix() {
        let parser = SNCFTrainParser()
        XCTAssertNil(parser.parse("FOO123"))
        XCTAssertNil(parser.parse("6123")) // generic, not SNCF responsibility
    }

    // MARK: - DB Parser

    func test_db_parsesICE() {
        let parser = DBTrainParser()
        let result = parser.parse("ICE74")
        XCTAssertEqual(result?.service, .dbICE)
        XCTAssertEqual(result?.number, "74")
    }

    func test_db_iceTakesPriorityOverIC() {
        // Critical: "ICE74" must NOT be parsed as IC + "E74"
        let parser = DBTrainParser()
        XCTAssertEqual(parser.parse("ICE74")?.service, .dbICE)
        XCTAssertEqual(parser.parse("IC2045")?.service, .dbIC)
    }

    func test_db_parsesRegional() {
        let parser = DBTrainParser()
        XCTAssertEqual(parser.parse("RE14821")?.service, .dbRE)
        XCTAssertEqual(parser.parse("RB12345")?.service, .dbRB)
    }

    // MARK: - UK Parser

    func test_uk_parsesValidHeadcode() {
        let parser = UKTrainParser()
        let result = parser.parse("1A23")
        XCTAssertEqual(result?.service, .ukHeadcode)
        XCTAssertEqual(result?.number, "1A23")
        XCTAssertNil(result?.prefix)
    }

    func test_uk_rejectsInvalidHeadcode() {
        let parser = UKTrainParser()
        XCTAssertNil(parser.parse("AB12"))   // letter first
        XCTAssertNil(parser.parse("1234"))   // all digits
        XCTAssertNil(parser.parse("1A2"))    // too short
        XCTAssertNil(parser.parse("1A234"))  // too long
    }

    // MARK: - Generic Parser

    func test_generic_parsesPlainDigits() {
        let parser = GenericTrainParser()
        let result = parser.parse("6123")
        XCTAssertEqual(result?.number, "6123")
        XCTAssertNil(result?.prefix)
        XCTAssertEqual(result?.service, .unknown)
    }

    func test_generic_respectsFallbackService() {
        let parser = GenericTrainParser(fallbackService: .sncfTER)
        XCTAssertEqual(parser.parse("9242")?.service, .sncfTER)
    }

    func test_generic_rejectsAlphabetic() {
        let parser = GenericTrainParser()
        XCTAssertNil(parser.parse("TGV6123"))
        XCTAssertNil(parser.parse("ABC"))
    }

    // MARK: - Composite

    func test_composite_dispatchesToCorrectParser() {
        let composite = CompositeTrainParser.default
        XCTAssertEqual(composite.parse("TGV 6123")?.service, .sncfTGV)
        XCTAssertEqual(composite.parse("ice74")?.service, .dbICE)
        XCTAssertEqual(composite.parse("1a23")?.service, .ukHeadcode)
        XCTAssertEqual(composite.parse("6123")?.service, .unknown)
    }

    func test_composite_preservesRawInput() {
        let composite = CompositeTrainParser.default
        let raw = "  tgv 6123 "
        let result = composite.parse(raw)
        XCTAssertEqual(result?.raw, raw)
        XCTAssertEqual(result?.normalized, "TGV6123")
    }

    func test_composite_returnsNilForGarbage() {
        let composite = CompositeTrainParser.default
        XCTAssertNil(composite.parse(""))
        XCTAssertNil(composite.parse("   "))
        XCTAssertNil(composite.parse("!!!"))
        XCTAssertNil(composite.parse("hello world"))
    }

    // MARK: - TrainService API source mapping

    func test_trainService_apiSourceIdentifiers() {
        XCTAssertEqual(TrainService.sncfTGV.apiSourceIdentifier, "sncf-tgv")
        XCTAssertEqual(TrainService.dbICE.apiSourceIdentifier, "db")
        XCTAssertEqual(TrainService.dbRE.apiSourceIdentifier, "db")
        XCTAssertNil(TrainService.unknown.apiSourceIdentifier)
        XCTAssertNil(TrainService.ukHeadcode.apiSourceIdentifier)
    }
}
