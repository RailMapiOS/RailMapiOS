//
//  Router.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 19/01/2025.
//

import Foundation
import SwiftUI
import CoreData

class Router: ObservableObject {
    @Published var path: [Flow] = []
    @Published var activeSheet: SheetType?

    enum Flow: Hashable {
        case journeys
        case addTicket(searchText: String?)
        case journeyDetails(objectID: NSManagedObjectID)
        case datePicker(dateRows: [DateRow])
        case stationPicker(DateRow)
        case confirmation(DateRow)
    }
    
    enum SheetType: Identifiable {
        case signIn
        case account
        
        var id: Int {
            switch self {
            case .signIn: return 1
            case .account: return 2
            }
        }
    }

    func navigate(to flow: Flow) {
        path.append(flow)
        LogManager.debug("Navigation vers: \(flow)", category: "navigation")
    }

    func navigateBack() {
        guard !path.isEmpty else { return }
        LogManager.debug("Fermeture de la page active \(path.last!)", category: "navigation")
        path.removeLast()
    }

    func navigateToRoot() {
        LogManager.debug("Fermeture de toutes les pages actives \(path)", category: "navigation")
        path.removeAll()
    }
    
    func presentSheet(_ sheet: SheetType) {
        activeSheet = sheet
        LogManager.debug("Présentation de la sheet: \(sheet)", category: "navigation")
    }
    
    func dismissSheet() {
        activeSheet = nil
        LogManager.debug("Fermeture de la sheet active", category: "navigation")
    }
}
