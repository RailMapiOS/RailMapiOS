//
//  BottomSheetView.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 12/07/2024.
//

import SwiftUI
import SwiftData
import AuthenticationServices

/// Une vue de feuille inférieure (bottom sheet) qui affiche les trajets et permet la navigation
///
/// Cette vue sert de point central pour afficher les trajets de l'utilisateur,
/// effectuer des recherches, et naviguer vers différentes parties de l'application.
/// Elle s'adapte dynamiquement en fonction de l'état de recherche et des résultats disponibles.
///
/// ## Fonctionnalités
/// - Affichage des trajets de l'utilisateur
/// - Recherche de trajets
/// - Navigation vers les détails d'un trajet
/// - Ajout de nouveaux trajets
/// - Gestion du profil utilisateur
struct BottomSheetView: View {
    // MARK: - Environnement et dépendances
    @EnvironmentObject var dataController: DataController
    
    // MARK: - Propriétés
    
    /// Résultats de la requête pour les trajets
    let journeys: [JourneySD]
    
    /// Routeur pour gérer la navigation
    @ObservedObject var router: Router
    
    /// Paramètres de la carte
    @ObservedObject var mapSettings: MapSettings
    
    /// ViewModel MVI
    @StateObject private var viewModel: BottomSheetViewModel
    
    /// Binding pour la taille de la feuille
    @Binding var sheetSize: PresentationDetent
    
    @FocusState private var isSearchFocused: Bool
    
    // MARK: - Initialisation
    
    init(
        journeys: [JourneySD],
        router: Router,
        mapSettings: MapSettings,
        sheetSize: Binding<PresentationDetent>,
        dataController: DataController
    ) {
        self.journeys = journeys
        self.router = router
        self.mapSettings = mapSettings
        self._sheetSize = sheetSize
        
        self._viewModel = StateObject(
            wrappedValue: BottomSheetViewModel(
                router: router,
                mapSettings: mapSettings,
                initialSheetSize: sheetSize.wrappedValue
            )
        )
        
        router.onNavigateBack = {
            mapSettings.clearRouteSelection()
        }
    }
    
    // MARK: - Corps de la vue
    
    var body: some View {
        NavigationStack(path: $router.path) {
            contentView
                .navigationDestination(for: Router.Flow.self, destination: navigationDestination)
                .sheet(
                    item: $router.activeSheet
                ) { sheetType in
                    switch sheetType {
                    case .signIn:
                        SignInView()
                            .environmentObject(UserStorage.shared)
                            .accessibilityIdentifier(AccessibilityID.BottomSheetView.Sheet.signInView)
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("Close") {
                                        viewModel.processIntent(.dismissSignIn)
                                    }
                                }
                            }
                            .onDisappear {
                                viewModel.processIntent(.dismissSignIn)
                            }
                            .onAppear {
                                LogManager.info("Affichage de la vue de connexion", category: "viewcycle")
                            }
                    case .account:
                        AccountView(userStorage: UserStorage.shared)
                            .accessibilityIdentifier(AccessibilityID.BottomSheetView.Sheet.accountView)
                            .onDisappear {
                                viewModel.processIntent(.dismissAccount)
                            }
                            .onAppear {
                                LogManager.info("Affichage de la vue de compte utilisateur", category: "viewcycle")
                            }
                    }
                }
                .onAppear {
                    viewModel.processIntent(.loadUserData)
                }
                .onReceive(journeys.publisher.collect()) { newJourneys in
                    viewModel.processIntent(.updateJourneys(newJourneys))
                }
                .onChange(of: viewModel.state.sheetSize) { _, newSize in
                    sheetSize = newSize
                }
                .onChange(of: router.path) { oldPath, newPath in
                    if oldPath.count > newPath.count {
                        LogManager.debug("Retour à la vue principale détecté", category: "navigation")
                        mapSettings.clearRouteSelection()
                    }
                }
        }.accessibilityIdentifier(AccessibilityID.BottomSheetView.navigationStack)
    }
    
    // MARK: - Vues composantes
    
    /// Contenu principal de la vue
    private var contentView: some View {
        VStack(spacing: 0) {
            if isOnRoot {
                HStack(spacing: 12) {
                    if !(viewModel.state.isSearchPresented || isSearchFocused) {
                        Text(viewModel.state.shouldShowAddTicket ? "Add a Journey" : "My Journeys")
                            .font(.title2.bold())
                            .foregroundStyle(.primary)
                            .layoutPriority(1)
                    }
                    CustomSearchBar(
                        text: Binding(
                            get: { viewModel.state.searchText },
                            set: { viewModel.processIntent(.searchTextChanged($0)) }
                        ),
                        isFocused: $isSearchFocused,
                        onFocusChange: handleSearchFocus
                    )
                    .frame(maxWidth: (viewModel.state.isSearchPresented || isSearchFocused) ? .infinity : 280, minHeight: 38)
                    .onTapGesture {
                        isSearchFocused = true
                    }
                    if viewModel.state.isSearchPresented || isSearchFocused {
                        Button(action: {
                            viewModel.processIntent(.searchTextChanged(""))
                            isSearchFocused = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Button(action: {
                            viewModel.processIntent(viewModel.isUserLoggedIn ? .toggleAccount : .toggleSignIn)
                        }) {
                            userProfileImage
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 6)
                Divider()
            }
            
            Group {
                if viewModel.state.shouldShowAddTicket {
                    AddTicketView(
                        router: router,
                        searchText: Binding(
                            get: { viewModel.state.searchText },
                            set: { viewModel.processIntent(.searchTextChanged($0)) }
                        )
                    )
                    .padding(.top)
                    .onAppear {
                        LogManager.info("Affichage de la vue d'ajout de ticket (recherche: '\(viewModel.state.searchText)')", category: "viewcycle")
                    }
                } else if viewModel.state.shouldShowEmptyState {
                    EmptyListJourneyView()
                        .onAppear {
                            LogManager.info("Affichage de la vue de liste vide", category: "viewcycle")
                        }
                } else {
                    journeyListView
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear() {
            LogManager.info("BottomSheetView apparaît", category: "viewcycle")
        }
        .onChange(of: isSearchFocused) { newValue in handleSearchFocus(newValue) }
        .onChange(of: router.path) { old, new in
            if !isOnRoot {
                // Réinitialiser la recherche quand on quitte la racine
                isSearchFocused = false
                viewModel.processIntent(.searchPresentationChanged(false))
                viewModel.processIntent(.searchTextChanged(""))
            }
        }
    }
    
    /// Synchronisation du focus de la searchbar avec l'état du ViewModel
    private func handleSearchFocus(_ focused: Bool) {
        if focused != viewModel.state.isSearchPresented {
            viewModel.processIntent(.searchPresentationChanged(focused))
        }
    }
    
    /// Liste des trajets filtrés
    private var journeyListView: some View {
        List(viewModel.state.filteredJourneys, id: \.id) { journey in
            JourneyRowView(journey: journey)
                .accessibilityIdentifier(AccessibilityID.BottomSheetView.JourneyRow.base(for: journey.id ?? UUID()))
                .onTapGesture {
                    viewModel.processIntent(.journeySelected(journey))
                }
        }
        .accessibilityIdentifier(AccessibilityID.BottomSheetView.journeyList)
        .listStyle(.plain)
        .onAppear {
            LogManager.debug("Affichage de la liste avec \(viewModel.state.filteredJourneys.count) trajets filtrés", category: "viewcycle")
        }
    }
    
    /// Image de profil utilisateur
    private var userProfileImage: some View {
        Group {
            if viewModel.isUserLoggedIn {
                if let uiImage = viewModel.profileUIImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 40)
                        .clipShape(.circle)
                        .padding(.horizontal, 10)
                } else {
                    Image(systemName: "person.crop.circle.fill.badge.checkmark")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 30)
                        .padding(.horizontal, 10)
                }
            } else {
                Image(systemName: "person.crop.circle.fill.badge.plus")
                    .resizable()
                    .foregroundStyle(.gray)
                    .scaledToFit()
                    .frame(height: 30)
                    .padding(.horizontal, 10)
            }
        }
        .accessibilityIdentifier(AccessibilityID.BottomSheetView.userProfileButton)
    }
    
    /// Feuille de compte utilisateur
    private var userAccountSheet: some View {
        Group {
            if viewModel.isUserLoggedIn {
                AccountView(userStorage: UserStorage.shared)
                    .onAppear {
                        LogManager.info("Affichage de la vue de compte utilisateur", category: "viewcycle")
                    }
            } else {
                SignInView()
                    .accessibilityIdentifier(AccessibilityID.BottomSheetView.Sheet.signInView)
                    .onAppear {
                        LogManager.info("Affichage de la vue de connexion", category: "viewcycle")
                    }
            }
        }
    }
    
    // MARK: - Fonctions de navigation
    
    /// Crée la destination de navigation appropriée en fonction du flux
    @ViewBuilder
    private func navigationDestination(for flow: Router.Flow) -> some View {
        switch flow {
        case .journeys:
            Text("My Journeys")
                .onAppear {
                    LogManager.info("Navigation vers la vue 'My Journeys'", category: "navigation")
                }
        case .addTicket(let searchText):
            AddTicketView(router: router, searchText: .constant(searchText ?? ""))
                .onAppear {
                    LogManager.info("Navigation vers la vue d'ajout de ticket avec recherche: '\(searchText ?? "")'", category: "navigation")
                }
        case .journeyDetails(let objectID):
            journeyDetailsView(for: objectID)
        case .stationPicker(let selectedDateRow):
            stationPickerView(for: selectedDateRow)
        case .confirmation(let pickedJourney):
            confirmationView(for: pickedJourney)
        case .datePicker(let dateRows):
            datePickerView(for: dateRows)
        }
    }
    
    /// Vue de détails d'un trajet
    @ViewBuilder
    private func journeyDetailsView(for journeyID: UUID) -> some View {
        if let journey = journeys.first(where: { $0.id == journeyID }) {
            JourneyDetailsV(journey: journey)
                .onAppear {
                    LogManager.info("Navigation vers les détails du trajet: \(journey.headsign ?? "inconnu")", category: "navigation")
                }
                .onDisappear {
                    LogManager.info("Sortie de la vue de détails du trajet", category: "navigation")
                    mapSettings.clearRouteSelection()
                }
        } else {
            Text("Journey not found")
                .onAppear {
                    LogManager.error("Tentative d'accès à un trajet inexistant (ID: \(journeyID))", category: "data_error")
                }
        }
    }
    /// Vue de sélection de station
    private func stationPickerView(for selectedDateRow: DateRow) -> some View {
        StationPickerView(viewModel: StationPickerViewModel(pickedJourney: selectedDateRow)) { pickedJourney in
            LogManager.info("Station sélectionnée pour le trajet", category: "user_action")
            router.navigate(to: .confirmation(pickedJourney))
        }
        .onAppear {
            LogManager.info("Navigation vers le sélecteur de station", category: "navigation")
        }
    }
    
    /// Vue de confirmation de trajet
    private func confirmationView(for pickedJourney: DateRow) -> some View {
        ConfirmationPickerView(viewModel: ConfirmationPickerViewModel(pickedJourney: pickedJourney, dataController: dataController)) {
            LogManager.info("Trajet confirmé et ajouté", category: "user_action")
            router.navigateToRoot()
        }
        .onAppear {
            LogManager.info("Navigation vers la confirmation du trajet", category: "navigation")
        }
    }
    
    /// Vue de sélection de date
    private func datePickerView(for dateRows: [DateRow]) -> some View {
        DatePickerView(viewModel: DatePickerViewModel(dateRows: dateRows), router: router) { selectedRow in
            LogManager.info("Date sélectionnée pour le trajet", category: "user_action")
            router.navigate(to: .stationPicker(selectedRow))
        }
        .onAppear {
            LogManager.info("Navigation vers le sélecteur de date avec \(dateRows.count) options", category: "navigation")
        }
    }
    
    private var isOnRoot: Bool {
        router.path.isEmpty || (router.path.last as? Router.Flow) == .journeys
    }
}

struct CustomSearchBar: View {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    var onFocusChange: (Bool) -> Void = { _ in }
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search…", text: $text)
                .textFieldStyle(.plain)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .font(.subheadline)
                .focused($isFocused)
                .onChange(of: isFocused) { newValue in onFocusChange(newValue) }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
