//
//  MapObscuredInsetsTests.swift
//  RailMapiOSTests
//
//  The wide-layout cases here cannot be checked by eye on this machine: iOS 27
//  resolves `presentationPlacement(.trailing)` to a bottom sheet on a portrait
//  iPhone, and there is no fold/ultra simulator to see the trailing one. These
//  lock in the intent instead.
//

import CoreGraphics
import Testing

@Suite("Map obscured insets", .tags(.map))
struct MapObscuredInsetsTests {

    /// A 402x874 iPhone screen.
    private let map = CGRect(x: 0, y: 0, width: 402, height: 874)

    @Test("A full-width bottom sheet only insets the bottom")
    func bottomSheet() {
        // Smallest detent: the sheet spans the width, bottom 30%.
        let sheet = CGRect(x: 0, y: 612, width: 402, height: 262)
        let insets = MapObscuredInsets.resolve(mapFrame: map, sheetFrame: sheet)

        #expect(insets.bottom == 262)
        #expect(insets.trailing == 0, "The overlap touches the trailing edge too, but the sheet is anchored to the bottom.")
        #expect(insets.leading == 0)
        #expect(insets.top == 0)
    }

    @Test("A full-height trailing sheet only insets the trailing edge")
    func trailingSheet() {
        // What a fold/ultra layout gets: a side panel down the trailing edge.
        let wide = CGRect(x: 0, y: 0, width: 900, height: 874)
        let sheet = CGRect(x: 540, y: 0, width: 360, height: 874)
        let insets = MapObscuredInsets.resolve(mapFrame: wide, sheetFrame: sheet)

        #expect(insets.trailing == 360)
        #expect(insets.bottom == 0, "The overlap reaches the bottom edge, but the sheet is anchored to the side.")
        #expect(insets.top == 0)
        #expect(insets.leading == 0)
    }

    @Test("A leading sheet insets the leading edge")
    func leadingSheet() {
        let wide = CGRect(x: 0, y: 0, width: 900, height: 874)
        let sheet = CGRect(x: 0, y: 0, width: 320, height: 874)
        let insets = MapObscuredInsets.resolve(mapFrame: wide, sheetFrame: sheet)

        #expect(insets.leading == 320)
        #expect(insets.trailing == 0)
    }

    @Test("A sheet inset from the screen edge still resolves to its own edge")
    func floatingSheet() {
        // iOS 27 floats the sheet slightly off the screen edges.
        let sheet = CGRect(x: 8, y: 620, width: 386, height: 246)
        let insets = MapObscuredInsets.resolve(mapFrame: map, sheetFrame: sheet)

        #expect(insets.bottom == 254, "Measured from the map's bottom to the sheet's top edge.")
        #expect(insets.leading == 0)
        #expect(insets.trailing == 0)
    }

    @Test("An unmeasured or absent sheet yields nothing")
    func noSheet() {
        #expect(MapObscuredInsets.resolve(mapFrame: map, sheetFrame: .zero) == .none)
        #expect(MapObscuredInsets.resolve(mapFrame: .zero, sheetFrame: map) == .none)
    }

    @Test("A sheet that does not overlap the map yields nothing")
    func disjoint() {
        // The iPad split view: sheet content lives beside the map, not over it.
        let sidebar = CGRect(x: -320, y: 0, width: 320, height: 874)
        #expect(MapObscuredInsets.resolve(mapFrame: map, sheetFrame: sidebar) == .none)
    }

    @Test("A sheet covering everything leaves the camera the whole rect")
    func fullyCovered() {
        // Better a framing behind the sheet than one squeezed into nothing.
        #expect(MapObscuredInsets.resolve(mapFrame: map, sheetFrame: map) == .none)
    }
}
