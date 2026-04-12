//
//  BottomSheetFeature.swift
//  RailMapiOS
//

import ComposableArchitecture
import Foundation
import SwiftUI

@Reducer
struct BottomSheetFeature {

    // MARK: - Navigation Path

    @Reducer(state: .equatable)
    enum Path {
        case journeyDetail(JourneyDetailFeature)
        case stationPicker(StationPickerFeature)
        case datePicker(DatePickerFeature)
        case confirmation(ConfirmationFeature)
    }

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        // Tabs
        var selectedTab: TabItem = .journeys

        // Search
        var searchText: String = ""
        var isSearchPresented: Bool = false
        var isSearchingAPI: Bool = false
        var searchResults: [VehicleJourney] = []

        // Journeys
        var allJourneys: [Journey] = []
        var filteredJourneys: [Journey] = []

        // Sheet
        var sheetSize: PresentationDetent = .medium

        // Navigation
        var path = StackState<Path.State>()
        @Presents var signIn: SignInFeature.State?
        @Presents var account: AccountFeature.State?

        // Computed
        var isCompact: Bool { sheetSize == .fraction(0.3) }
        var shouldShowEmptyState: Bool { !isSearchPresented && filteredJourneys.isEmpty }
        var isUserLoggedIn: Bool { UserStorage.shared.isLoggedIn() }

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.selectedTab == rhs.selectedTab &&
            lhs.searchText == rhs.searchText &&
            lhs.isSearchPresented == rhs.isSearchPresented &&
            lhs.isSearchingAPI == rhs.isSearchingAPI &&
            lhs.filteredJourneys.compactMap(\.id) == rhs.filteredJourneys.compactMap(\.id) &&
            lhs.sheetSize == rhs.sheetSize &&
            lhs.path == rhs.path &&
            lhs.signIn == rhs.signIn &&
            lhs.account == rhs.account
        }
    }

    // MARK: - Action

    enum Action: BindableAction {
        // Binding (for searchText, sheetSize via $store)
        case binding(BindingAction<State>)

        // Tabs
        case tabSelected(TabItem)

        // Search
        case searchTextChanged(String)
        case searchResultsReceived([VehicleJourney])
        case searchFailed

        // Journeys
        case journeysUpdated([Journey])
        case journeyTapped(Journey)

        // Sheet
        case sheetSizeChanged(PresentationDetent)

        // Auth
        case profileButtonTapped

        // Navigation
        case path(StackActionOf<Path>)
        case signIn(PresentationAction<SignInFeature.Action>)
        case account(PresentationAction<AccountFeature.Action>)
    }

    // MARK: - Dependencies

    @Dependency(\.vehicleJourneyClient) var vehicleJourneyClient
    @Dependency(\.journeyFilterClient) var journeyFilter
    @Dependency(\.userStorageClient) var userStorage

    private enum CancelID { case search }

    // MARK: - Body

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            // MARK: Tabs

            case .tabSelected(let tab):
                state.selectedTab = tab
                state.isSearchPresented = (tab == .search)
                if tab == .search && state.sheetSize == .fraction(0.3) {
                    state.sheetSize = .medium
                }
                return .none

            // MARK: Search

            case .searchTextChanged(let text):
                state.searchText = text
                state.filteredJourneys = journeyFilter.filterJourneys(state.allJourneys, text)

                guard !text.isEmpty, state.selectedTab == .search else {
                    state.isSearchingAPI = false
                    return .cancel(id: CancelID.search)
                }

                state.isSearchingAPI = true
                return .run { [text] send in
                    do {
                        let results = try await vehicleJourneyClient.fetchVehicleJourneys(text, "sncf-ter")
                        await send(.searchResultsReceived(results))
                    } catch {
                        await send(.searchFailed)
                    }
                }
                .debounce(id: CancelID.search, for: .milliseconds(400), scheduler: DispatchQueue.main)
                .cancellable(id: CancelID.search, cancelInFlight: true)

            case .searchResultsReceived(let results):
                state.isSearchingAPI = false
                state.searchResults = results
                guard let journey = results.first else { return .none }
                state.path.append(.stationPicker(StationPickerFeature.State(journey: journey)))
                return .none

            case .searchFailed:
                state.isSearchingAPI = false
                return .none

            // MARK: Journeys

            case .journeysUpdated(let journeys):
                state.allJourneys = journeys
                state.filteredJourneys = journeyFilter.filterJourneys(journeys, state.searchText)
                return .none

            case .journeyTapped(let journey):
                guard let journeyID = journey.id else { return .none }
                state.path.append(.journeyDetail(JourneyDetailFeature.State(journey: journey)))
                return .none

            // MARK: Sheet

            case .sheetSizeChanged(let size):
                if state.selectedTab == .search && size == .fraction(0.3) {
                    state.sheetSize = .medium
                } else {
                    state.sheetSize = size
                }
                return .none

            // MARK: Auth

            case .profileButtonTapped:
                if userStorage.isLoggedIn() {
                    state.account = AccountFeature.State(user: userStorage.loadUser())
                } else {
                    state.signIn = SignInFeature.State()
                }
                return .none

            // MARK: Navigation Path delegates

            case .path(.element(_, action: .stationPicker(.delegate(.stationsConfirmed(let dateRow))))):
                let dateRows = journeyFilter.buildDateRows(state.searchResults, dateRow.departureStationID, dateRow.arrivalStationID)
                state.path.append(.datePicker(DatePickerFeature.State(
                    dateRows: dateRows,
                    displayedMonth: Date()
                )))
                return .none

            case .path(.element(_, action: .datePicker(.delegate(.dateSelected(let dateRow))))):
                state.path.append(.confirmation(ConfirmationFeature.State(pickedJourney: dateRow)))
                return .none

            case .path(.element(_, action: .confirmation(.delegate(.journeyConfirmed)))):
                state.path.removeAll()
                state.searchText = ""
                state.searchResults = []
                return .none

            case .path(.element(_, action: .journeyDetail(.delegate(.dismissed)))):
                return .none

            case .path:
                return .none

            // MARK: Sheet delegates

            case .signIn(.presented(.delegate(.signedIn))):
                state.signIn = nil
                return .none

            case .signIn:
                return .none

            case .account(.presented(.delegate(.signedOut))):
                state.account = nil
                return .none

            case .account:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
        .ifLet(\.$signIn, action: \.signIn) { SignInFeature() }
        .ifLet(\.$account, action: \.account) { AccountFeature() }
    }
}
