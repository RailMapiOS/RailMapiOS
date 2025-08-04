//
//  JourneysListView.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 12/07/2024.
//

import SwiftUI

/// Une vue qui affiche une liste de trajets ferroviaires SwiftData
struct JourneysListView: View {
    // MARK: - Propriétés
    /// Collection de trajets à afficher
    private let journeys: [Journey]
    
    /// Chemin de navigation pour la navigation programmatique
    @State private var path: NavigationPath
    
    // MARK: - Initialisation
    /// Crée une nouvelle vue de liste de trajets
    /// - Parameters:
    ///   - journeys: Les trajets à afficher
    ///   - path: Le chemin de navigation pour la navigation programmatique
    init(journeys: [Journey], path: NavigationPath) {
        self.journeys = journeys
        self._path = State(initialValue: path)
        LogManager.info("Initialisation de JourneysListView avec \(journeys.count) trajets", category: "viewcycle")
    }
    
    // MARK: - Corps de la vue
    var body: some View {
        Group {
            if journeys.isEmpty {
                emptyStateView
            } else {
                journeyListView
            }
        }
    }
    
    // MARK: - Vues composantes
    /// Vue affichée lorsqu'aucun trajet n'est disponible
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Text("Prenons le train vers l'inconnu")
                .fontWeight(.bold)
            
            Text("Utilisez la barre de recherche ou")
                .font(.subheadline)
                .foregroundStyle(.gray)
            
            Button {
                LogManager.info("Bouton 'Ajoutez un trajet aléatoire' pressé", category: "user_action")
                print("trajet aléatoire")
            } label: {
                Text("Ajoutez un trajet aléatoire")
                    .font(.subheadline)
            }
        }
        .onAppear {
            LogManager.debug("Affichage de la vue vide (aucun trajet)", category: "viewcycle")
        }
    }
    
    /// Vue affichant la liste des trajets disponibles
    private var journeyListView: some View {
        List(journeys, id: \.id) { journey in
            JourneyRowView(journey: journey)
                .onTapGesture {
                    LogManager.info("Trajet sélectionné: \(journey.headsign ?? "inconnu")", category: "navigation")
                    if let journeyID = journey.id {
                        path.append(journeyID)
                    }
                }
        }
        .listStyle(.plain)
        .onAppear {
            LogManager.debug("Affichage de la liste avec \(journeys.count) trajets", category: "viewcycle")
        }
    }
}

#Preview {
    let journey = Journey()
    journey.headsign = "Test Journey"
    journey.company = "SNCF"
    
    return JourneysListView(journeys: [journey], path: NavigationPath())
}
