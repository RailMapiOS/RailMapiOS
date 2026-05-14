//
//  StringExt.swift
//  Helpers
//
//  Created by Jérémie Patot on 28/02/2025.
//

import Foundation

public extension String {

    func convertToDouble() -> Double? {
        let formatter = NumberFormatter()
        formatter.decimalSeparator = ","
        return formatter.number(from: self)?.doubleValue
    }
}
