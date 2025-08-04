//
// Router.swift
// RailMapiOS
//
// Created by Jérémie Patot on 19/01/2025.
//

import SwiftUI
import Foundation

class Router: ObservableObject {
    // Chemin de navigation
    @Published var path: [Flow] = []
    
    // Feuilles modales
    @Published var activeSheet: SheetType?
    
    // Call-back déclenché lors d’un retour arrière
    var onNavigateBack: (() -> Void)?
    
    // MARK: - Routes
    enum Flow: Hashable {
        case journeys
        case addTicket(searchText: String?)
        case journeyDetails(id: UUID)
        case datePicker(dateRows: [DateRow])
        case stationPicker(DateRow)
        case confirmation(DateRow)
    }
    
    // MARK: - Sheets
    enum SheetType: Identifiable {
        case signIn
        case account
        
        var id: Int {
            switch self {
            case .signIn:   1
            case .account:  2
            }
        }
    }
    
    // MARK: - Helpers
    func navigate(to flow: Flow) {
        path.append(flow)
        LogManager.debug("Navigation vers: \(flow)", category: "navigation")
    }
    
    func navigateBack() {
        guard !path.isEmpty else { return }
        path.removeLast()
        onNavigateBack?()
        LogManager.debug("Retour arrière", category: "navigation")
    }
    
    func navigateToRoot() {
        path.removeAll()
        onNavigateBack?()
        LogManager.debug("Retour à la racine", category: "navigation")
    }
    
    func presentSheet(_ sheet: SheetType) {
        activeSheet = sheet
        LogManager.debug("Présentation de la sheet: \(sheet)", category: "navigation")
    }
    
    func dismissSheet() {
        activeSheet = nil
        onNavigateBack?()
        LogManager.debug("Fermeture de la sheet active", category: "navigation")
    }
}
