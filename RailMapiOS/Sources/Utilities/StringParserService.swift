//
//  StringParserService.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 21/03/2025.
//

import Foundation

protocol StringParserServiceProtocol {
    func extractName(from input: String) -> String
}

class StringParserService: StringParserServiceProtocol {
    func extractName(from input: String) -> String {
        let pattern = ".*:(OCE[\\w ]+)-\\d+"
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            if let match = regex.firstMatch(in: input, options: [], range: NSRange(input.startIndex..., in: input)) {
                let range = Range(match.range(at: 1), in: input)!
                var extractedString = String(input[range])
                
                if extractedString.hasPrefix("OCE") {
                    extractedString = String(extractedString.dropFirst(3))
                }
                
                return extractedString.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch {
            LogManager.error("Regex Error: \(error)")
        }
        return ""
    }
}
