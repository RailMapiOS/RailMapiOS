//
//  StringExt.swift
//  Helpers
//
//  Created by Jérémie Patot on 28/02/2025.
//

import Foundation

public extension String {

    /// Parses a decimal number written with either separator, independently of
    /// the device locale.
    ///
    /// The previous implementation used a `NumberFormatter` pinned to a comma
    /// decimal separator. API payloads use a dot (`"43.611206"`, Navitia's
    /// format), which that formatter rejected — in *every* locale — so callers
    /// fell back to `0.0` and every stop of a saved journey landed at (0, 0),
    /// off the coast of Africa. `Double.init` is locale-independent; the comma
    /// pass is kept for sources that do write `"43,611206"`.
    func convertToDouble() -> Double? {
        let trimmed = trimmingCharacters(in: .whitespaces)
        if let value = Double(trimmed) { return value }
        return Double(trimmed.replacingOccurrences(of: ",", with: "."))
    }
}
