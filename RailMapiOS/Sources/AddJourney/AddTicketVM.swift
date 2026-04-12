//
//  AddTicketVM.swift
//  RailMap
//
//  Created by Jérémie - Ada on 14/09/2023.
//

import Foundation
import SwiftUI

/// `AddTicketViewModel` gère la logique métier liée à l'ajout de tickets, en utilisant des services pour séparer les responsabilités.
@MainActor
final class AddTicketVM: ObservableObject {

    /// Les voyages en véhicule actuellement disponibles.
    @Published var vehicleJourneys: [VehicleJourney] = []
    
    /// Les dates formatées associées aux voyages en véhicule.
    @Published var datePickerVehicleJourneys: [Date: String] = [:]
    
    // Services
    private let vehicleJourneyService: any VehicleJourneyServiceProtocol & Sendable
    private let dateFormatterService: any DateFormatterServiceProtocol
    private let stringParserService: any StringParserServiceProtocol
    
    init(
        vehicleJourneyService: any VehicleJourneyServiceProtocol & Sendable = VehicleJourneyService(),
        dateFormatterService : any DateFormatterServiceProtocol = DateFormatterService(),
        stringParserService  : any StringParserServiceProtocol = StringParserService()
    ) {
        self.vehicleJourneyService = vehicleJourneyService
        self.dateFormatterService  = dateFormatterService
        self.stringParserService   = stringParserService
    }
    
    // MARK: - API
    /// Fetches vehicle journeys from the API for the given headsign and data source.
    /// - Parameters:
    ///   - headsign: The trip headsign to search for.
    ///   - source: The data source identifier (e.g. "sncf-ter", "sncf-tgv"). Defaults to "sncf-ter".
    func fetchHeadsignAddTicket(headsign: String, source: String = "sncf-ter") async {
        do {
            vehicleJourneys = try await vehicleJourneyService.fetchVehicleJourneys(headsign: headsign, source: source)
        } catch {
            LogManager.error("Error: \(error)")
        }
    }
    /// Obtient les jours de passage pour les voyages en véhicule spécifiés.
    /// - Parameter vehicleJourneys: Les voyages en véhicule à analyser.
    /// - Returns: Un dictionnaire associant les identifiants de voyage aux dates de passage.
    func getPassageDays(from journeys: [VehicleJourney]) -> [String: [Date]] {
        vehicleJourneyService.getPassageDays(from: journeys)
    }
    
    /// Formate une date en chaîne de caractères au format `dd/MM/yy`.
    /// - Parameter date: La date à formater.
    /// - Returns: La date formatée en chaîne de caractères.
    func formatDate(_ date: Date) -> String {
        return dateFormatterService.formatDate(date)
    }
    
    /// Formate une chaîne de caractères de date en un format lisible.
    /// - Parameter dateString: La chaîne de caractères représentant la date.
    /// - Returns: La date formatée en chaîne de caractères ou "N/A" si la conversion échoue.
    func formatDateLettre(_ dateString: String) -> String {
        return dateFormatterService.formatDateLettre(dateString)
    }
    
    /// Extrait un nom de la chaîne d'entrée en utilisant une expression régulière.
    /// - Parameter input: La chaîne d'entrée contenant le nom à extraire.
    /// - Returns: Le nom extrait ou une chaîne vide si l'extraction échoue.
    func extractName(from input: String) -> String {
        return stringParserService.extractName(from: input)
    }
    
    /// Formate une chaîne de caractères de date au format `HHmmss` en `HH:mm`.
    /// - Parameter dateString: La chaîne de caractères représentant l'heure.
    /// - Returns: L'heure formatée en chaîne de caractères ou un message d'erreur si la conversion échoue.
    func formattedHour(from dateString: String) -> String {
        return dateFormatterService.formattedHour(from: dateString)
    }
}
