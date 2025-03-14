//
//  BottomSheetState.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 14/03/2025.
//

import SwiftUI
import CoreData
import AuthenticationServices

// MARK: - Model (État)

/// Représente l'état complet de la vue BottomSheet
struct BottomSheetState: Equatable {
    /// État de la recherche
    var searchText: String = ""
    var isSearchPresented: Bool = false
    
    /// État de l'interface utilisateur
    var sheetSize: PresentationDetent = .medium
    var showSignIn: Bool = false
    
    /// État des données
    var filteredJourneys: [Journey] = []
    var cachedJourneyCount: Int = 0
    
    /// Détermine quel contenu afficher
    var shouldShowAddTicket: Bool {
        isSearchPresented && filteredJourneys.isEmpty
    }
    
    var shouldShowEmptyState: Bool {
        !isSearchPresented && filteredJourneys.isEmpty
    }
    
    static func == (lhs: BottomSheetState, rhs: BottomSheetState) -> Bool {
        lhs.searchText == rhs.searchText &&
        lhs.isSearchPresented == rhs.isSearchPresented &&
        lhs.showSignIn == rhs.showSignIn &&
        lhs.cachedJourneyCount == rhs.cachedJourneyCount
    }
}

// MARK: - Intent (Actions)

/// Représente toutes les intentions/actions possibles dans la vue
enum BottomSheetIntent {
    case searchTextChanged(String)
    case searchPresentationChanged(Bool)
    case toggleSignIn
    case dismissSignIn
    case journeySelected(Journey)
    case updateJourneys([Journey])
    case loadUserData
}

// MARK: - ViewModel

/// ViewModel qui implémente le pattern MVI pour BottomSheetView
class BottomSheetViewModel: ObservableObject {
    // Dépendances
    private let moc: NSManagedObjectContext
    private let router: Router
    private let mapSettings: MapSettings
    private let userStorage: UserStorage
    
    // État observable
    @Published private(set) var state: BottomSheetState = BottomSheetState()
    
    init(
        moc: NSManagedObjectContext,
        router: Router,
        mapSettings: MapSettings,
        userStorage: UserStorage = UserStorage.shared,
        initialSheetSize: PresentationDetent
    ) {
        self.moc = moc
        self.router = router
        self.mapSettings = mapSettings
        self.userStorage = userStorage
        self.state.sheetSize = initialSheetSize
        
        LogManager.info("Initialisation de BottomSheetViewModel", category: "viewmodel")
    }
    
    /// Traite les intentions et met à jour l'état
    func processIntent(_ intent: BottomSheetIntent) {
        switch intent {
        case .searchTextChanged(let newText):
            LogManager.debug("Texte de recherche modifié: '\(state.searchText)' -> '\(newText)'", category: "search")
            state.searchText = newText
            
        case .searchPresentationChanged(let isPresented):
            LogManager.debug("État de recherche modifié: \(state.isSearchPresented) -> \(isPresented)", category: "ui_state")
            state.isSearchPresented = isPresented
            
            if isPresented {
                state.sheetSize = .large
                LogManager.debug("Recherche présentée, changement de taille du sheet à large", category: "ui_state")
            }
            
        case .toggleSignIn:
            LogManager.info("Bouton de profil utilisateur pressé", category: "user_action")
            if state.showSignIn {
                router.dismissSheet()
            } else {
                router.presentSheet(userStorage.isLoggedIn() ? .account : .signIn)
            }
            state.showSignIn.toggle()
            
        case .dismissSignIn:
            LogManager.info("Fermeture de la vue de connexion", category: "user_action")
            router.dismissSheet()
            state.showSignIn = false
            
        case .journeySelected(let journey):
            LogManager.info("Trajet sélectionné: \(journey.headsign ?? "inconnu")", category: "navigation")
            mapSettings.updateJourneys(from: [journey])
            router.navigate(to: .journeyDetails(objectID: journey.objectID))
            
        case .updateJourneys(let journeys):
            if Set(journeys.map { $0.objectID }) != Set(state.filteredJourneys.map { $0.objectID }) {
                filterJourneys(journeys)
                mapSettings.updateJourneys(from: journeys)
                LogManager.info("Mise à jour des trajets: \(journeys.count) trajets", category: "data")
            }
        case .loadUserData:
            LogManager.info("Chargement des données utilisateur", category: "data")
            userStorage.loadUser()
        }
    }
    
    /// Filtre les trajets en fonction du texte de recherche
    private func filterJourneys(_ journeys: [Journey]) {
        // Éviter de recalculer si le nombre de trajets n'a pas changé et que le texte de recherche est vide
        if journeys.count == state.cachedJourneyCount && state.searchText.isEmpty {
            state.filteredJourneys = journeys
            return
        }
        
        state.cachedJourneyCount = journeys.count
        
        let filtered = state.searchText.isEmpty ? 
            journeys : 
            journeys.filter { $0.headsign?.contains(state.searchText) ?? false }
        
        state.filteredJourneys = filtered
        LogManager.debug("Filtrage des trajets: \(filtered.count) résultats pour '\(state.searchText)'", category: "search")
    }
    
    // Accesseurs pour les dépendances
    var currentUser: User? { userStorage.currentUser }
    var isUserLoggedIn: Bool { userStorage.isLoggedIn() }
}

