//
//  BottomSheetView.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 12/07/2024.
//

import SwiftUI
import CoreData
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
    
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    
    // MARK: - Propriétés
    
    /// Résultats de la requête pour les trajets
    let journeys: FetchedResults<Journey>
    
    /// Routeur pour gérer la navigation
    @ObservedObject var router: Router
    
    /// Paramètres de la carte
    @ObservedObject var mapSettings: MapSettings
    
    /// ViewModel MVI
    @StateObject private var viewModel: BottomSheetViewModel
    
    /// Binding pour la taille de la feuille
    @Binding var sheetSize: PresentationDetent
    
    // MARK: - Initialisation
    
    init(
        journeys: FetchedResults<Journey>,
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
                moc: dataController.container.viewContext,
                router: router,
                mapSettings: mapSettings,
                initialSheetSize: sheetSize.wrappedValue
            )
        )
    }
    
    // MARK: - Corps de la vue
    
    var body: some View {
        NavigationStack(path: $router.path) {
            contentView
                .navigationDestination(for: Router.Flow.self, destination: navigationDestination)
                .toolbar { toolbarContent }
                .searchable(
                    text: Binding(
                        get: { viewModel.state.searchText },
                        set: { viewModel.processIntent(.searchTextChanged($0)) }
                    ),
                    isPresented: Binding(
                        get: { viewModel.state.isSearchPresented },
                        set: { viewModel.processIntent(.searchPresentationChanged($0)) }
                    ),
                    placement: .navigationBarDrawer(displayMode: .always)
                )
                .searchPresentationToolbarBehavior(.avoidHidingContent)
                .sheet(
                    item: $router.activeSheet
                ) { sheetType in
                    switch sheetType {
                    case .signIn:
                        SignInView()
                            .environmentObject(UserStorage.shared)
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
        }
    }
    
    // MARK: - Vues composantes
    
    /// Contenu principal de la vue
    private var contentView: some View {
        VStack {
            if viewModel.state.shouldShowAddTicket {
                AddTicketV(
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
        .onAppear() {
            LogManager.info("BottomSheetView apparaît", category: "viewcycle")
        }
    }
    
    /// Liste des trajets filtrés
    private var journeyListView: some View {
        List(viewModel.state.filteredJourneys, id: \.objectID) { journey in
            JourneyRowView(journey: journey)
                .onTapGesture {
                    viewModel.processIntent(.journeySelected(journey))
                }
        }
        .listStyle(.plain)
        .onAppear {
            LogManager.debug("Affichage de la liste avec \(viewModel.state.filteredJourneys.count) trajets filtrés", category: "viewcycle")
        }
    }
    
    /// Contenu de la barre d'outils
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Text(viewModel.state.shouldShowAddTicket ? "Add a Journey" : "My Journeys")
                .fontWeight(.bold)
                .font(.title)
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                viewModel.processIntent(viewModel.isUserLoggedIn ?.toggleAccount : .toggleSignIn)
            } label: {
                userProfileImage
            }
        }
    }
    
    /// Image de profil utilisateur
    private var userProfileImage: some View {
        Group {
            if viewModel.isUserLoggedIn {
                if let user = viewModel.currentUser,
                   let data = user.profileImage,
                   let uiImage = UIImage(data: data) {
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
            AddTicketV(router: router, searchText: .constant(searchText ?? ""))
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
    private func journeyDetailsView(for objectID: NSManagedObjectID) -> some View {
        if let journey = moc.object(with: objectID) as? Journey {
            JourneyDetailsV(journey: journey)
                .onAppear {
                    LogManager.info("Navigation vers les détails du trajet: \(journey.headsign ?? "inconnu")", category: "navigation")
                }
        } else {
            Text("Journey not found")
                .onAppear {
                    LogManager.error("Tentative d'accès à un trajet inexistant (ObjectID: \(objectID))", category: "data_error")
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
}
