//
//  DateFormatterService.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 21/03/2025.
//

import Foundation

@preconcurrency
protocol DateFormatterServiceProtocol {
    func formatDate(_ date: Date) -> String
    func formatDateLettre(_ dateString: String) -> String
    func formattedHour(from dateString: String) -> String
    
    // Nouvelles méthodes pour JourneyRowViewModel
    func formatJourneyDate(_ date: Date?) -> String
    func formatJourneyTime(_ date: Date?) -> String
    func calculateDuration(startDate: Date?, endDate: Date?) -> String
}

class DateFormatterService: DateFormatterServiceProtocol {
    func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yy"
        return dateFormatter.string(from: date)
    }
    
    func formatDateLettre(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        
        if let date = dateFormatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "dd MMMM"
            return outputFormatter.string(from: date)
        } else {
            return "N/A"
        }
    }
    
    func formattedHour(from dateString: String) -> String {
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "HH:mm"

        // Try multiple input formats
        let inputFormats = ["HHmmss", "HH:mm:ss", "HH:mm"]
        for format in inputFormats {
            let parser = DateFormatter()
            parser.dateFormat = format
            if let date = parser.date(from: dateString) {
                return outputFormatter.string(from: date)
            }
        }

        // Last resort: if it looks like "083000", try stripping and reformatting
        let stripped = dateString.replacingOccurrences(of: ":", with: "")
        if stripped.count >= 4 {
            let hh = stripped.prefix(2)
            let mm = stripped.dropFirst(2).prefix(2)
            return "\(hh):\(mm)"
        }

        LogManager.warning("Unrecognized time format: '\(dateString)'", category: "formatting")
        return dateString
    }
}

// Implémentation des nouvelles méthodes
extension DateFormatterService {
    func formatJourneyDate(_ date: Date?) -> String {
        guard let date = date else {
            LogManager.warning("Tentative de formatage d'une date null", category: "formatting")
            return "Date non disponible"
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EE. dd MMM."
        return dateFormatter.string(from: date)
    }
    
    func formatJourneyTime(_ date: Date?) -> String {
        guard let date = date else {
            LogManager.warning("Tentative de formatage d'une heure null", category: "formatting")
            return "Heure non disponible"
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter.string(from: date)
    }
    
    func calculateDuration(startDate: Date?, endDate: Date?) -> String {
        guard let startDate = startDate, let endDate = endDate else {
            LogManager.error("Impossible de calculer la durée: dates de début ou de fin manquantes", category: "calculations")
            return "N/A"
        }
        let interval = endDate.timeIntervalSince(startDate)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return String(format: "%02dh%02d", hours, minutes)
    }
}
