//
//  JourneyRowViewModel.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 26/07/2024.
//

import Foundation

class JourneyRowViewModel: ObservableObject {
    private let journey: Journey
    
    @Published private(set) var headsign: String
    @Published private(set) var departureTime: String
    @Published private(set) var departureDate: String
    @Published private(set) var departureLabel: String
    @Published private(set) var arrivalTime: String
    @Published private(set) var arrivalDate: String
    @Published private(set) var arrivalLabel: String
    @Published private(set) var compagny: String
    @Published private(set) var duration: String
    
    init(journey: Journey) {
        self.journey = journey
        
        self.headsign = journey.headsign ?? "N/A"
        self.departureTime = ""
        self.departureDate = ""
        self.departureLabel = ""
        self.arrivalTime =  ""
        self.arrivalDate =  ""
        self.arrivalLabel = ""
        self.compagny = ""
        self.duration = ""
        
        self.departureTime = formatTime(journey.startDate)
        self.departureDate = formatDate(journey.startDate)
        self.departureLabel = departureStop(journey)?.stopinfo?.label ?? "N/A departureLabel"
        self.arrivalTime = formatTime(journey.endDate)
        self.arrivalDate = formatDate(journey.endDate)
        self.arrivalLabel = arrivalStop(journey)?.stopinfo?.label ?? "N/A arrivalLabel"
        self.compagny = journey.company ?? "N/A company"
        self.duration = calculateDuration(startDate: journey.startDate, endDate: journey.endDate)
        
        LogManager.info("Initialisation de JourneyRowViewModel pour le trajet vers \(journey.headsign ?? "destination inconnue")")
    }
    
    // Méthodes privées pour le calcul initial
    private func departureStop(_ journey: Journey) -> Stop? {
        let stop = (journey.stops as? Set<Stop>)?.first { $0.status == "departure" }
        if stop == nil {
            LogManager.error("Arrêt de départ non trouvé pour le trajet \(journey.headsign ?? "inconnu")", category: "data", privacy: .private)
        }
        return stop
    }
    
    private func arrivalStop(_ journey: Journey) -> Stop? {
        let stop = (journey.stops as? Set<Stop>)?.first { $0.status == "arrival" }
        if stop == nil {
            LogManager.error("Arrêt d'arrivée non trouvé pour le trajet \(journey.headsign ?? "inconnu")", category: "data", privacy: .private)
        }
        return stop
    }
    
    private func calculateDuration(startDate: Date?, endDate: Date?) -> String {
        guard let startDate = startDate, let endDate = endDate else {
            LogManager.error("Impossible de calculer la durée: dates de début ou de fin manquantes", category: "calculations")
            return "N/A"
        }
        let interval = endDate.timeIntervalSince(startDate)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return String(format: "%02dh%02d", hours, minutes)
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else {
            LogManager.warning("Tentative de formatage d'une date null", category: "formatting")
            return "Date non disponible"
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EE. dd MMM."
        return dateFormatter.string(from: date)
    }
    
    private func formatTime(_ date: Date?) -> String {
        guard let date = date else {
            LogManager.warning("Tentative de formatage d'une heure null", category: "formatting")
            return "Heure non disponible"
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter.string(from: date)
    }
}
