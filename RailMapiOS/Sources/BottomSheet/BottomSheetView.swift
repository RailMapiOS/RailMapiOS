//
//  BottomSheetView.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 12/07/2024.
//

import SwiftUI
import SwiftData
import AuthenticationServices

struct BottomSheetView: View {
    // MARK: - Environment
    @EnvironmentObject var dataController: DataController

    // MARK: - Properties
    let journeys: [Journey]
    @ObservedObject var router: Router
    @ObservedObject var mapSettings: MapSettings
    @StateObject private var viewModel: BottomSheetViewModel
    @Binding var sheetSize: PresentationDetent
    @State private var selectedTab: TabItem = .journeys

    private var isCompact: Bool {
        sheetSize == .fraction(0.3)
    }

    // MARK: - Init
    init(
        journeys: [Journey],
        router: Router,
        mapSettings: MapSettings,
        sheetSize: Binding<PresentationDetent>
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

    // MARK: - Bindings

    private var searchTextBinding: Binding<String> {
        Binding(
            get: { viewModel.state.searchText },
            set: { viewModel.processIntent(.searchTextChanged($0)) }
        )
    }

    private var searchPresentedBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.isSearchPresented },
            set: { viewModel.processIntent(.searchPresentationChanged($0)) }
        )
    }

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $router.path) {
            contentWithBars
//                .navigationTitle(selectedTab.title)
//                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: Router.Flow.self, destination: navigationDestination)
                .sheet(item: $router.activeSheet, content: sheetContent)
                .onAppear { viewModel.processIntent(.loadUserData) }
                .onChange(of: selectedTab) { _, newTab in
                    viewModel.processIntent(.searchPresentationChanged(newTab == .search))
                    if newTab == .search && sheetSize == .fraction(0.3) {
                        sheetSize = .medium
                    }
                }
                .onReceive(journeys.publisher.collect()) { newJourneys in
                    viewModel.processIntent(.updateJourneys(newJourneys))
                }
                .onChange(of: viewModel.state.sheetSize) { _, newSize in
                    sheetSize = newSize
                }
                .onChange(of: sheetSize) { _, newSize in
                    if selectedTab == .search && newSize == .fraction(0.3) {
                        sheetSize = .medium
                    }
                }
                .onChange(of: router.path) { oldPath, newPath in
                    if oldPath.count > newPath.count {
                        mapSettings.clearRouteSelection()
                    }
                }
        }
        .accessibilityIdentifier(AccessibilityID.BottomSheetView.navigationStack)
    }

    // MARK: - Content with Bars

    @ViewBuilder
    private var contentWithBars: some View {
        if #available(iOS 26.0, *) {
            tabContent
                .safeAreaBar(edge: .bottom) {
                    bottomBarContent
                }
                .safeAreaBar(edge: .top) {
                    topBarButton
                }
        } else {
            tabContent
                .safeAreaInset(edge: .bottom) {
                    bottomBarContent
                        .background(.regularMaterial)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        topBarButton
                    }
                }
        }
    }

    private var bottomBarContent: some View {
        VStack {
            if selectedTab == .search {
                bottomSearchBar
            }
            CustomTabBarView(selectedTab: $selectedTab)
        }
    }

    private var topBarButton: some View {
        HStack {
            Text(selectedTab.title)
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.leading)
            Spacer()
            Button {
                viewModel.processIntent(viewModel.isUserLoggedIn ? .toggleAccount : .toggleSignIn)
            } label: {
                userProfileImage
            }
        }
        .padding()
    }

    // MARK: - Sheet Content

    @ViewBuilder
    private func sheetContent(_ sheetType: Router.SheetType) -> some View {
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
        case .account:
            AccountView(userStorage: UserStorage.shared)
                .accessibilityIdentifier(AccessibilityID.BottomSheetView.Sheet.accountView)
                .onDisappear {
                    viewModel.processIntent(.dismissAccount)
                }
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .journeys:
            journeysContent
        case .friends:
            friendsContent
        case .profile:
            profileContent
        case .search:
            searchContent
        }
    }

    // MARK: - Bottom Search Bar

    private var bottomSearchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.system(size: 16))

            TextField("Rechercher un trajet...", text: searchTextBinding)
                .textFieldStyle(.plain)
                .font(.body)
                .submitLabel(.search)

            if !viewModel.state.searchText.isEmpty {
                Button {
                    viewModel.processIntent(.searchTextChanged(""))
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Journeys Tab

    private var journeysContent: some View {
        Group {
            if viewModel.state.shouldShowEmptyState {
                EmptyListJourneyView(compact: isCompact)
            } else {
                journeyListView
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Search Tab

    private var searchContent: some View {
        Group {
            if viewModel.state.searchText.isEmpty {
                ScrollView {
                    VStack(spacing: 12) {
                        if !isCompact {
                            Image(systemName: "magnifyingglass")
                                .resizable()
                                .foregroundStyle(.tertiary)
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: 60)
                                .padding(.bottom, 8)
                        }
                        Text("Rechercher un trajet")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Entrez un numéro de train")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
                }
            } else if !viewModel.state.filteredJourneys.isEmpty {
                List(viewModel.state.filteredJourneys, id: \.id) { journey in
                    JourneyRowView(journey: journey)
                        .onTapGesture {
                            viewModel.processIntent(.journeySelected(journey))
                        }
                }
                .listStyle(.plain)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        if viewModel.isSearchingAPI {
                            ProgressView()
                                .padding(.bottom, 8)
                        } else if !isCompact {
                            Image(systemName: "magnifyingglass")
                                .resizable()
                                .foregroundStyle(.tertiary)
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: 60)
                                .padding(.bottom, 8)
                        }
                        Text(viewModel.isSearchingAPI ? "Recherche..." : "Entrez un numéro de train")
                            .font(.title2)
                            .fontWeight(.bold)
                        if !viewModel.isSearchingAPI {
                            Text("ex. 6234, 8541...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
                }
            }
        }
    }

    // MARK: - Friends Tab (placeholder)

    private var friendsContent: some View {
        ScrollView {
            VStack(spacing: 12) {
                if !isCompact {
                    Image(systemName: "person.3")
                        .resizable()
                        .foregroundStyle(.tertiary)
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 80)
                        .padding(.bottom, 8)
                }
                Text("Mes Amis")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Bientôt disponible")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 16)
        }
    }

    // MARK: - Profile Tab

    private var profileContent: some View {
        ScrollView {
            Group {
                if viewModel.isUserLoggedIn {
                    AccountView(userStorage: UserStorage.shared)
                } else {
                    VStack(spacing: 12) {
                        if !isCompact {
                            Image(systemName: "person.crop.circle")
                                .resizable()
                                .foregroundStyle(.tertiary)
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: 80)
                                .padding(.bottom, 8)
                        }
                        Text("Se connecter")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Connectez-vous pour accéder à votre profil")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("Se connecter") {
                            viewModel.processIntent(.toggleSignIn)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 8)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 16)
        }
    }

    // MARK: - Journey List

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
    }

    // MARK: - Profile Image

    private var userProfileImage: some View {
        Group {
            if viewModel.isUserLoggedIn {
                if let uiImage = viewModel.profileUIImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 30)
                        .clipShape(.circle)
                } else {
                    Image(systemName: "person.crop.circle.fill.badge.checkmark")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 30)
                }
            } else {
                Image(systemName: "person.crop.circle.fill.badge.plus")
                    .resizable()
                    .foregroundStyle(.gray)
                    .scaledToFit()
                    .frame(height: 30)
            }
        }
        .accessibilityIdentifier(AccessibilityID.BottomSheetView.userProfileButton)
    }

    // MARK: - Navigation Destinations

    @ViewBuilder
    private func navigationDestination(for flow: Router.Flow) -> some View {
        switch flow {
        case .journeys:
            Text("My Journeys")
        case .addTicket(let searchText):
            AddTicketView(router: router, searchText: .constant(searchText ?? ""))
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

    @ViewBuilder
    private func journeyDetailsView(for journeyID: UUID) -> some View {
        if let journey = journeys.first(where: { $0.id == journeyID }) {
            JourneyDetailView(journey: journey)
                .onDisappear {
                    mapSettings.clearRouteSelection()
                }
        } else {
            Text("Journey not found")
        }
    }

    private func stationPickerView(for selectedDateRow: DateRow) -> some View {
        StationPickerView(viewModel: StationPickerViewModel(pickedJourney: selectedDateRow)) { pickedJourneyWithStations in
            // Use ALL search results (multiple trips share stops but have different calendars)
            let allJourneys = viewModel.searchResults.isEmpty
                ? [pickedJourneyWithStations.journey]
                : viewModel.searchResults

            let passageDays = VehicleJourneyService().getPassageDays(from: allJourneys)

            // Merge all dates from all journeys into a single sorted list
            var allDates: [Date] = []
            for (_, dates) in passageDays {
                allDates.append(contentsOf: dates)
            }
            let today = Calendar.current.startOfDay(for: Date())
            let uniqueDates = Array(Set(allDates)).filter { $0 >= today }.sorted()

            let dateRows = uniqueDates.map { date in
                var row = DateRow(
                    journeyId: pickedJourneyWithStations.journeyId,
                    date: date,
                    journey: pickedJourneyWithStations.journey
                )
                row.departureStationID = pickedJourneyWithStations.departureStationID
                row.arrivalStationID = pickedJourneyWithStations.arrivalStationID
                return row
            }
            router.navigate(to: .datePicker(dateRows: dateRows))
        }
    }

    private func confirmationView(for pickedJourney: DateRow) -> some View {
        ConfirmationPickerView(viewModel: ConfirmationPickerViewModel(pickedJourney: pickedJourney, dataController: dataController)) {
            router.navigateToRoot()
        }
    }

    private func datePickerView(for dateRows: [DateRow]) -> some View {
        DatePickerView(viewModel: DatePickerViewModel(dateRows: dateRows), router: router) { selectedRow in
            router.navigate(to: .confirmation(selectedRow))
        }
    }
}
