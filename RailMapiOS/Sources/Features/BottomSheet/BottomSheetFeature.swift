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
        var searchResults: [SearchResult] = []
        /// All raw trips from the last search, used by the station picker flow.
        var rawSearchTrips: [VehicleJourney] = []

        // Journeys
        var allJourneys: [Journey] = []
        var filteredJourneys: [Journey] = []

        /// Mirror of `AppFeature.realtimeUpdates`. Synced from the parent so
        /// the journey list can derive refund eligibility per row without
        /// each row triggering its own fetch.
        var realtimeUpdates: [UUID: RealtimeStatus] = [:]

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

        // MARK: Section ordering (priority-ranked)
        //
        //   1. Active   — currently in transit, no delay/cancellation
        //   2. Delayed  — any positive delay OR cancelled, banner not dismissed
        //   3. Upcoming — scheduled in the future, no delay
        //   4. Archived — past, no delay

        /// Currently in transit (`startDate ≤ now ≤ endDate`) with no
        /// reported delay or cancellation.
        var activeJourneys: [Journey] {
            filteredJourneys
                .filter { $0.isActive && !hasDelayOrCancellation($0) }
                .sorted(by: byStartDateAscending)
        }

        /// Delayed or cancelled journeys (any state), banner not dismissed.
        var delayedJourneys: [Journey] {
            filteredJourneys
                .filter { hasDelayOrCancellation($0) }
                .sorted(by: byStartDateDescending)
        }

        /// Future journeys, not yet active, no delay/cancellation.
        var upcomingJourneys: [Journey] {
            filteredJourneys
                .filter { !$0.isActive && !$0.isPast && !hasDelayOrCancellation($0) }
                .sorted(by: byStartDateAscending)
        }

        /// Past, no delay/cancellation (or dismissed).
        var pastJourneys: [Journey] {
            filteredJourneys
                .filter { $0.isPast && !hasDelayOrCancellation($0) }
                .sorted(by: byStartDateDescending)
        }

        // MARK: Helpers

        /// True when the journey has any positive arrival delay or is
        /// cancelled, AND the user hasn't dismissed the alert banner.
        /// Used both for section filtering and to derive the row badge.
        func hasDelayOrCancellation(_ journey: Journey) -> Bool {
            guard journey.refundBannerDismissed != true,
                  let id = journey.id,
                  let status = realtimeUpdates[id]
            else { return false }
            if status.isCancelled { return true }
            return (status.arrivalDelaySeconds ?? 0) >= 60
        }

        /// Returns the badge to render on a row, if any.
        func badge(for journey: Journey) -> SavedJourneyBadge? {
            guard let id = journey.id, let status = realtimeUpdates[id] else { return nil }
            if status.isCancelled { return .cancelled }
            let delaySec = status.arrivalDelaySeconds ?? 0
            guard delaySec >= 60 else { return nil }
            return .delayed(minutes: delaySec / 60)
        }

        private func byStartDateAscending(_ a: Journey, _ b: Journey) -> Bool {
            (a.startDate ?? .distantFuture) < (b.startDate ?? .distantFuture)
        }

        private func byStartDateDescending(_ a: Journey, _ b: Journey) -> Bool {
            (a.startDate ?? .distantPast) > (b.startDate ?? .distantPast)
        }

        /// Lock the sheet in large mode during the add-journey flow or when search has results.
        /// Journey detail (read-only view of a saved journey) is NOT considered the add flow.
        var isInAddJourneyFlow: Bool {
            if !searchResults.isEmpty { return true }
            return path.contains { element in
                switch element {
                case .stationPicker, .datePicker, .confirmation: return true
                case .journeyDetail: return false
                }
            }
        }

        /// Detents allowed for the current state.
        /// During the add flow, only `.large` is offered so the sheet can't be dragged down.
        var availableDetents: Set<PresentationDetent> {
            isInAddJourneyFlow ? [.large] : [.fraction(0.3), .medium, .large]
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.selectedTab == rhs.selectedTab &&
            lhs.searchText == rhs.searchText &&
            lhs.isSearchPresented == rhs.isSearchPresented &&
            lhs.isSearchingAPI == rhs.isSearchingAPI &&
            lhs.filteredJourneys.compactMap(\.id) == rhs.filteredJourneys.compactMap(\.id) &&
            // Critical: drives the Delayed/Cancelled section + per-row badge
            // and strikethrough times. Skipping it here means SwiftUI never
            // reruns the list body when realtime arrives.
            lhs.realtimeUpdates == rhs.realtimeUpdates &&
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
        case searchResultTapped(SearchResult)

        // Journeys
        case journeysUpdated([Journey])
        case journeyTapped(Journey)
        case journeyDeleted(Journey)

        // Sheet
        case sheetSizeChanged(PresentationDetent)

        // Auth
        case profileButtonTapped

        #if DEBUG
        // Debug menu — replaces the profile button in DEBUG builds.
        case insertMockJourney(MockJourneyKind)
        #endif

        // Navigation
        case path(StackActionOf<Path>)
        case signIn(PresentationAction<SignInFeature.Action>)
        case account(PresentationAction<AccountFeature.Action>)
    }

    // MARK: - Dependencies

    @Dependency(\.vehicleJourneyClient) var vehicleJourneyClient
    @Dependency(\.journeyFilterClient) var journeyFilter
    @Dependency(\.userStorageClient) var userStorage
    @Dependency(\.dataControllerClient) var dataController
    @Dependency(\.trainIdentifierParser) var trainParser
    @Dependency(\.searchResultsClient) var searchResultsClient

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
                // Stay at the current detent — user can keep the sheet compact
                // while on the search tab; the placeholder collapses to a single
                // line of guidance below the search bar.
                return .none

            // MARK: Search

            case .searchTextChanged(let text):
                state.searchText = text
                state.filteredJourneys = journeyFilter.filterJourneys(state.allJourneys, text)

                // Cancel inflight search if text empty or tab not search
                guard !text.isEmpty, state.selectedTab == .search else {
                    state.isSearchingAPI = false
                    state.searchResults = []
                    state.rawSearchTrips = []
                    return .cancel(id: CancelID.search)
                }

                // Pre-flight: parse the input. If unparseable → no API call.
                guard let identifier = trainParser.parse(text) else {
                    state.isSearchingAPI = false
                    state.searchResults = []
                    state.rawSearchTrips = []
                    return .cancel(id: CancelID.search)
                }

                // Use detected service's API source, or fall back to "sncf-ter".
                let source = identifier.service.apiSourceIdentifier ?? "sncf-ter"
                let trainNumber = identifier.number

                state.isSearchingAPI = true
                return .run { [trainNumber, source] send in
                    do {
                        let results = try await vehicleJourneyClient.fetchVehicleJourneys(trainNumber, source)
                        await send(.searchResultsReceived(results))
                    } catch {
                        await send(.searchFailed)
                    }
                }
                .debounce(id: CancelID.search, for: .milliseconds(500), scheduler: DispatchQueue.main)
                .cancellable(id: CancelID.search, cancelInFlight: true)

            case .searchResultsReceived(let results):
                state.isSearchingAPI = false
                state.rawSearchTrips = results
                state.searchResults = searchResultsClient.groupResults(results)
                // Expand the sheet so the user sees all results comfortably
                if !state.searchResults.isEmpty, state.sheetSize != .large {
                    state.sheetSize = .large
                }
                return .none

            case .searchResultTapped(let result):
                state.sheetSize = .large
                state.path.append(.stationPicker(StationPickerFeature.State(journey: result.representative)))
                return .none

            case .searchFailed:
                state.isSearchingAPI = false
                state.searchResults = []
                state.rawSearchTrips = []
                return .none

            // MARK: Journeys

            case .journeysUpdated(let journeys):
                state.allJourneys = journeys
                state.filteredJourneys = journeyFilter.filterJourneys(journeys, state.searchText)

                #if DEBUG
                // Seed realtimeUpdates for mock journeys (which don't go
                // through the live polling loop) so the refund section
                // surfaces them in the list.
                for journey in journeys {
                    guard let id = journey.id,
                          let tripID = journey.idVehiculeJourney,
                          let status = MockJourneyFactory.realtimeStatus(forTripID: tripID)
                    else { continue }
                    state.realtimeUpdates[id] = status
                }
                #endif

                return .none

            case .journeyTapped(let journey):
                guard let journeyID = journey.id else { return .none }
                state.path.append(.journeyDetail(JourneyDetailFeature.State(journey: journey)))
                return .none

            case .journeyDeleted(let journey):
                guard let journeyID = journey.id else { return .none }
                return .run { _ in
                    await dataController.deleteJourney(journeyID)
                }

            // MARK: Sheet

            case .sheetSizeChanged(let size):
                state.sheetSize = size
                return .none

            // MARK: Auth

            case .profileButtonTapped:
                if userStorage.isLoggedIn() {
                    state.account = AccountFeature.State(user: userStorage.loadUser())
                } else {
                    state.signIn = SignInFeature.State()
                }
                return .none

            #if DEBUG
            case .insertMockJourney(let kind):
                let (mock, _) = MockJourneyFactory.make(kind)
                // The realtime status is cached inside MockJourneyFactory keyed
                // by tripID — JourneyDetailFeature.onAppear pulls it from there
                // instead of hitting the network.
                return .run { _ in
                    await dataController.saveJourney(mock)
                }
            #endif

            // MARK: Navigation Path delegates

            case .path(.element(_, action: .stationPicker(.delegate(.stationsConfirmed(let dateRow))))):
                let dateRows = journeyFilter.buildDateRows(state.rawSearchTrips, dateRow.departureStationID, dateRow.arrivalStationID)
                state.sheetSize = .large
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
