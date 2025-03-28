//
//  BottomSheetState.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 14/03/2025.
//

import SwiftUI
import CoreData
import AuthenticationServices
import MapKit

// MARK: - Model (État)

/// Représente l'état complet de la vue BottomSheet
struct BottomSheetState: Equatable {
    /// État de la recherche
    var searchText: String = ""
    var isSearchPresented: Bool = false
    
    /// État de l'interface utilisateur
    var sheetSize: PresentationDetent = .medium
    var showSignIn: Bool = false
    var showAccount: Bool = false
    
    /// État des données
    var filteredJourneys: [Journey] = []
    var cachedJourneyCount: Int = 0
    
    /// Détermine quel contenu afficher
    var shouldShowAddTicket: Bool {
        isSearchPresented && (searchText.isEmpty ? false : filteredJourneys.isEmpty)
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
    case toggleAccount
    case dismissAccount
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
    
    // Trajets non filtrés
    private var journeys: [Journey] = []
    
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
            
            if state.searchText != newText {
                state.searchText = newText
                filterJourneys(journeys)
            }
            
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
            
        case .toggleAccount:
            LogManager.info("Bouton de profil utilisateur pressé", category: "user_action")
            if state.showAccount {
                router.dismissSheet()
            } else {
                router.presentSheet(userStorage.isLoggedIn() ? .account : .signIn)
            }
            state.showAccount.toggle()
            
        case .dismissAccount:
            LogManager.info("Fermeture de la vue de compte", category: "user_action")
            router.dismissSheet()
            state.showAccount = false
          
        case .journeySelected(let journey):
            LogManager.info("Trajet sélectionné: \(journey.headsign ?? "inconnu")", category: "navigation")
              
              // Trouver la route correspondante dans mapSettings
              if let routeIndex = mapSettings.trainRoutes.firstIndex(where: { route in
                  // Logique pour identifier la route correspondant au journey
                  // Par exemple, vérifier les coordonnées de départ et d'arrivée
                  if let stops = journey.stops as? NSSet,
                     let stopsArray = stops.allObjects as? [Stop],
                     let firstStop = stopsArray.first(where: { $0.status?.lowercased() == "departure" }),
                     let lastStop = stopsArray.last(where: { $0.status?.lowercased() == "arrival" }),
                     let firstInfo = firstStop.stopinfo,
                     let lastInfo = lastStop.stopinfo {
                      
                      let firstCoord = CLLocationCoordinate2D(latitude: firstInfo.latitude, longitude: firstInfo.longitude)
                      let lastCoord = CLLocationCoordinate2D(latitude: lastInfo.latitude, longitude: lastInfo.longitude)
                      
                      return route.coordinates.first == firstCoord && route.coordinates.last == lastCoord
                  }
                  return false
              }) {
                  // Sélectionner la route
                  mapSettings.selectRoute(mapSettings.trainRoutes[routeIndex])
              }
              router.navigate(to: .journeyDetails(objectID: journey.objectID))
            
        case .updateJourneys(let newJourneys):
            if Set(newJourneys.map { $0.objectID }) != Set(journeys.map { $0.objectID }) {
                 LogManager.info("Mise à jour des trajets: \(newJourneys.count) trajets", category: "data")
                 journeys = newJourneys
                 filterJourneys(newJourneys)
                 mapSettings.updateJourneys(from: newJourneys)
             }
        case .loadUserData:
            LogManager.info("Chargement des données utilisateur", category: "data")
            userStorage.loadUser()
        }
    }
    
    /// Filtre les trajets en fonction du texte de recherche
    /// Filtre les trajets en fonction du texte de recherche
    private func filterJourneys(_ journeys: [Journey]) {
        LogManager.debug("Filtrage des trajets avec le texte: '\(state.searchText)'", category: "search")
        
        // Le filtrage doit toujours être effectué lorsque searchText change
        let filtered = state.searchText.isEmpty ?
            journeys :
            journeys.filter { journey in
                if let headsign = journey.headsign {
                    return headsign.localizedCaseInsensitiveContains(state.searchText)
                }
                return false
            }
        
        // Mettre à jour l'état seulement si les résultats ont changé
        if filtered.map({ $0.objectID }) != state.filteredJourneys.map({ $0.objectID }) {
            state.filteredJourneys = filtered
            state.cachedJourneyCount = journeys.count
            LogManager.debug("Filtrage des trajets: \(filtered.count) résultats pour '\(state.searchText)'", category: "search")
        }
    }

    // Accesseurs pour les dépendances
    var currentUser: User? { userStorage.currentUser }
    var isUserLoggedIn: Bool { userStorage.isLoggedIn() }
}

