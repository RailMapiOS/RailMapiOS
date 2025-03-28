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
        let formatter = DateFormatter()
        formatter.dateFormat = "HHmmss"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        if let date = formatter.date(from: dateString) {
            return dateFormatter.string(from: date)
        }
        return "Erreur, mauvais format de date"
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
