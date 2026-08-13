//
//  MapObscuredInsets.swift
//  RailMapiOS
//
//  Works out which edge of the map a sheet is covering, and by how much.
//
//  iOS 27 can place the journeys sheet against the trailing edge
//  (`presentationPlacement(.trailing)` in `AppView`) instead of the bottom, and
//  resolves that request differently depending on how much room the layout has —
//  a portrait iPhone still gets a bottom sheet. Rather than hardcode a side and
//  a width per device class, the sheet reports its own frame and the map derives
//  the obscured edge from the overlap. That covers bottom, trailing and leading
//  placements, any detent, and the wide iPhone layouts this is preparing for,
//  without a number to calibrate.
//

import CoreGraphics

/// How much of the map each edge loses to the sheet, in points.
struct MapObscuredInsets: Equatable {
    var top: CGFloat = 0
    var bottom: CGFloat = 0
    var leading: CGFloat = 0
    var trailing: CGFloat = 0

    static let none = MapObscuredInsets()

    /// Derives the insets from the sheet's frame, both rects in the same
    /// coordinate space.
    ///
    /// A sheet only ever covers the map from one edge, but its overlap usually
    /// touches three: a bottom sheet spanning the full width overlaps the
    /// leading and trailing edges too. Excluding it from any *one* of those
    /// edges would work geometrically, so the anchored edge is the one whose
    /// inset is smallest — for a full-width bottom sheet that is the bottom, for
    /// a full-height side sheet it is the side. Picking the minimum is what
    /// makes this placement-agnostic.
    static func resolve(mapFrame: CGRect, sheetFrame: CGRect) -> MapObscuredInsets {
        guard !mapFrame.isEmpty, !sheetFrame.isEmpty else { return .none }
        let overlap = mapFrame.intersection(sheetFrame)
        guard !overlap.isNull, !overlap.isEmpty else { return .none }

        let candidates: [(inset: CGFloat, apply: (inout MapObscuredInsets) -> Void)] = [
            (mapFrame.maxY - overlap.minY, { $0.bottom = mapFrame.maxY - overlap.minY }),
            (overlap.maxY - mapFrame.minY, { $0.top = overlap.maxY - mapFrame.minY }),
            (mapFrame.maxX - overlap.minX, { $0.trailing = mapFrame.maxX - overlap.minX }),
            (overlap.maxX - mapFrame.minX, { $0.leading = overlap.maxX - mapFrame.minX })
        ]

        guard let smallest = candidates.min(by: { $0.inset < $1.inset }) else { return .none }
        // A sheet covering the map entirely leaves nothing to frame; keeping the
        // insets at zero lets the camera fall back to the full rect rather than
        // collapsing to an unusable area.
        guard smallest.inset < min(mapFrame.width, mapFrame.height) else { return .none }

        var insets = MapObscuredInsets()
        smallest.apply(&insets)
        return insets
    }
}
