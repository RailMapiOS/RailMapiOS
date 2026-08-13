//
//  JourneyCoordinateParsingTests.swift
//  RailMapiOSTests
//
//  Regression guard for the August 2026 "map centred on the equator" bug.
//
//  `String.convertToDouble()` used a NumberFormatter pinned to a comma decimal
//  separator, while the API sends Navitia's dot format ("43.611206"). It
//  returned nil for every real coordinate, in every locale, and
//  `DateRow.toNewJourneyModel` turned that into `0.0` — so every stop of a
//  saved journey landed at (0, 0), the map framed the Gulf of Guinea and the
//  route was nowhere near the visible region.
//
//  Coordinates below are the ones GET /stop/8512?source=sncf-tgv actually
//  returns for TGV INOUI 8512 (Toulouse -> Paris).
//

import Foundation
import Helpers
import Testing

@Suite("Journey coordinate parsing", .tags(.map))
struct JourneyCoordinateParsingTests {

    // MARK: - The parser itself

    @Test("Dot decimals — the format the API actually sends — parse")
    func parsesDotDecimals() {
        #expect("43.611206".convertToDouble() == 43.611206)
        #expect("1.453616".convertToDouble() == 1.453616)
        #expect("48.841172".convertToDouble() == 48.841172)
    }

    @Test("Negative longitudes parse — Bordeaux is west of Greenwich")
    func parsesNegativeValues() {
        #expect("-0.556697".convertToDouble() == -0.556697)
    }

    @Test("Comma decimals still parse, for sources that use them")
    func parsesCommaDecimals() {
        #expect("43,611206".convertToDouble() == 43.611206)
        #expect("-0,556697".convertToDouble() == -0.556697)
    }

    @Test("Surrounding whitespace is tolerated")
    func parsesPaddedValues() {
        #expect(" 43.611206 ".convertToDouble() == 43.611206)
    }

    @Test("Genuinely unparseable input stays nil rather than becoming a number")
    func rejectsGarbage() {
        #expect("".convertToDouble() == nil)
        #expect("N/A".convertToDouble() == nil)
        #expect("abc".convertToDouble() == nil)
    }

    // MARK: - End to end, through the add-journey conversion

    @Test("A searched trip keeps its real coordinates once saved")
    func toNewJourneyModelKeepsRealCoordinates() throws {
        let journey = try decodeVehicleJourney(latitude: "43.611206", longitude: "1.453616")
        var row = DateRow(journeyId: journey.id, date: Date(), journey: journey)
        row.departureStationID = "stop_point:departure"
        row.arrivalStationID = "stop_point:arrival"

        let model = try #require(row.toNewJourneyModel())
        let departure = try #require(model.stops.first?.stopInfo)

        #expect(departure.latitude == 43.611206,
                "Parsed back to nil and defaulted to 0.0 — the Gulf of Guinea bug.")
        #expect(departure.longitude == 1.453616)
    }

    @Test("An unusable coordinate stays nil instead of collapsing to (0, 0)")
    func toNewJourneyModelLeavesBadCoordinatesNil() throws {
        let journey = try decodeVehicleJourney(latitude: "N/A", longitude: "N/A")
        var row = DateRow(journeyId: journey.id, date: Date(), journey: journey)
        row.departureStationID = "stop_point:departure"
        row.arrivalStationID = "stop_point:arrival"

        let model = try #require(row.toNewJourneyModel())
        let departure = try #require(model.stops.first?.stopInfo)

        #expect(departure.latitude == nil)
        #expect(departure.longitude == nil)
        // `MapService.generateTrainRoutes` and `PositionEstimator` both skip
        // stops without coordinates, so nil is safe where 0.0 was not.
    }

    // MARK: - Fixture

    /// Minimal payload matching the shape of `GET /stop/:number`, so the test
    /// exercises the real `Codable` path rather than a hand-built struct.
    private func decodeVehicleJourney(latitude: String, longitude: String) throws -> VehicleJourney {
        let json = """
        {
          "id": "OCESN8512F1187_F:OUI:FR:Line::A74B127A::87611004:87391003:5:1714:20260913",
          "name": "8512",
          "headsign": "8512",
          "journey_pattern": { "id": "journey_pattern:0", "name": "8512" },
          "trip": { "id": "OCESN8512F1187", "name": "8512" },
          "codes": [],
          "disruptions": [],
          "validity_pattern": { "beginning_date": "20260101", "days": "1" },
          "calendars": [
            {
              "week_pattern": {
                "monday": true, "tuesday": true, "wednesday": true, "thursday": true,
                "friday": true, "saturday": false, "sunday": false
              },
              "active_periods": [{ "begin": "20260101", "end": "20261231" }]
            }
          ],
          "stop_times": [
            {
              "arrival_time": "171200", "utc_arrival_time": "151200",
              "departure_time": "171400", "utc_departure_time": "151400",
              "headsign": "8512",
              "pickup_allowed": true, "drop_off_allowed": true, "skipped_stop": false,
              "stop_point": {
                "id": "stop_point:departure", "name": "Toulouse Matabiau",
                "label": "Toulouse Matabiau", "codes": [], "links": [], "equipments": [],
                "coord": { "lat": "\(latitude)", "lon": "\(longitude)" }
              }
            },
            {
              "arrival_time": "215600", "utc_arrival_time": "195600",
              "departure_time": "215600", "utc_departure_time": "195600",
              "headsign": "8512",
              "pickup_allowed": true, "drop_off_allowed": true, "skipped_stop": false,
              "stop_point": {
                "id": "stop_point:arrival", "name": "Paris Montparnasse Hall 1 - 2",
                "label": "Paris Montparnasse", "codes": [], "links": [], "equipments": [],
                "coord": { "lat": "48.841172", "lon": "2.320514" }
              }
            }
          ]
        }
        """
        return try JSONDecoder().decode(VehicleJourney.self, from: Data(json.utf8))
    }
}
