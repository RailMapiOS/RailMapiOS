//
//  BottomSheetState.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 14/03/2025.
//

import SwiftUI
import SwiftData
import AuthenticationServices
import MapKit

// MARK: - Model (État)
struct BottomSheetState: Equatable {
    var searchText: String = ""
    var isSearchPresented: Bool = false
    var sheetSize: PresentationDetent = .medium
    var showSignIn: Bool = false
    var showAccount: Bool = false
    var filteredJourneys: [Journey] = []
    var cachedJourneyCount: Int = 0

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
enum BottomSheetIntent {
    case searchTextChanged(String)
    case searchPresentationChanged(Bool)
    case searchAndNavigate(String)
    case toggleSignIn
    case dismissSignIn
    case toggleAccount
    case dismissAccount
    case journeySelected(Journey)
    case updateJourneys([Journey])
    case loadUserData
}

// MARK: - ViewModel
@MainActor
class BottomSheetViewModel: ObservableObject {
    private let router: Router
    private let mapSettings: MapSettings
    private let userStorage: UserStorage
    private let vehicleJourneyService: any VehicleJourneyServiceProtocol & Sendable

    @Published private(set) var state: BottomSheetState = BottomSheetState()

    /// Search API state
    @Published private(set) var isSearchingAPI: Bool = false
    /// All vehicle journeys returned by the last search (multiple trips for same headsign).
    @Published private(set) var searchResults: [VehicleJourney] = []
    private var searchTask: Task<Void, Never>?

    private var journeys: [Journey] = []

    init(
        router: Router,
        mapSettings: MapSettings,
        userStorage: UserStorage = UserStorage.shared,
        vehicleJourneyService: any VehicleJourneyServiceProtocol & Sendable = VehicleJourneyService(),
        initialSheetSize: PresentationDetent
    ) {
        self.router = router
        self.mapSettings = mapSettings
        self.userStorage = userStorage
        self.vehicleJourneyService = vehicleJourneyService
        self.state.sheetSize = initialSheetSize
    }

    func processIntent(_ intent: BottomSheetIntent) {
        switch intent {
        case .searchTextChanged(let newText):
            if state.searchText != newText {
                state.searchText = newText
                filterJourneys(journeys)
                if state.isSearchPresented {
                    searchAndNavigateToStationPicker(headsign: newText)
                }
            }

        case .searchPresentationChanged(let isPresented):
            state.isSearchPresented = isPresented
            if isPresented {
                state.sheetSize = .large
            }

        case .searchAndNavigate(let headsign):
            searchAndNavigateToStationPicker(headsign: headsign)

        case .toggleSignIn:
            if state.showSignIn {
                router.dismissSheet()
            } else {
                router.presentSheet(userStorage.isLoggedIn() ? .account : .signIn)
            }
            state.showSignIn.toggle()

        case .dismissSignIn:
            router.dismissSheet()
            state.showSignIn = false

        case .toggleAccount:
            if state.showAccount {
                router.dismissSheet()
            } else {
                router.presentSheet(userStorage.isLoggedIn() ? .account : .signIn)
            }
            state.showAccount.toggle()

        case .dismissAccount:
            router.dismissSheet()
            state.showAccount = false

        case .journeySelected(let journey):
            if let routeIndex = mapSettings.trainRoutes.firstIndex(where: { route in
                if let stops = journey.stops,
                   let firstStop = stops.first(where: { $0.status?.lowercased() == "departure" }),
                   let lastStop = stops.last(where: { $0.status?.lowercased() == "arrival" }),
                   let firstInfo = firstStop.stopinfo,
                   let lastInfo = lastStop.stopinfo,
                   let firstLat = firstInfo.latitude,
                   let firstLon = firstInfo.longitude,
                   let lastLat = lastInfo.latitude,
                   let lastLon = lastInfo.longitude {

                    let firstCoord = CLLocationCoordinate2D(latitude: firstLat, longitude: firstLon)
                    let lastCoord = CLLocationCoordinate2D(latitude: lastLat, longitude: lastLon)

                    return route.stopCoordinates.first == firstCoord && route.stopCoordinates.last == lastCoord
                }
                return false
            }) {
                mapSettings.selectRoute(mapSettings.trainRoutes[routeIndex])
            }

            if let journeyID = journey.id {
                router.navigate(to: .journeyDetails(id: journeyID))
            }

        case .updateJourneys(let newJourneys):
            if Set(newJourneys.compactMap { $0.id }) != Set(journeys.compactMap { $0.id }) {
                journeys = newJourneys
                filterJourneys(newJourneys)
                mapSettings.updateJourneys(from: newJourneys)
            }

        case .loadUserData:
            userStorage.loadUser()
        }
    }

    // MARK: - Search API → Navigate

    private func searchAndNavigateToStationPicker(headsign: String) {
        searchTask?.cancel()
        guard !headsign.isEmpty else {
            isSearchingAPI = false
            return
        }

        isSearchingAPI = true
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }

            do {
                let results = try await vehicleJourneyService.fetchVehicleJourneys(headsign: headsign, source: "sncf-ter")
                guard !Task.isCancelled, !results.isEmpty else {
                    self.isSearchingAPI = false
                    return
                }

                // Store all results — they share the same stops but have different calendars
                self.searchResults = results
                let journey = results.first!
                let templateRow = DateRow(journeyId: journey.id, date: Date(), journey: journey)
                self.isSearchingAPI = false
                router.navigate(to: .stationPicker(templateRow))
            } catch {
                self.isSearchingAPI = false
                LogManager.error("Search API error: \(error)", category: "search")
            }
        }
    }

    private func filterJourneys(_ journeys: [Journey]) {
        let filtered = state.searchText.isEmpty ?
            journeys :
            journeys.filter { journey in
                if let headsign = journey.headsign {
                    return headsign.localizedCaseInsensitiveContains(state.searchText)
                }
                return false
            }

        if filtered.compactMap({ $0.id }) != state.filteredJourneys.compactMap({ $0.id }) {
            state.filteredJourneys = filtered
            state.cachedJourneyCount = journeys.count
        }
    }

    var currentUser: User? { userStorage.currentUser }
    var isUserLoggedIn: Bool { userStorage.isLoggedIn() }
    var profileUIImage: UIImage? {
        guard let user = self.currentUser,
              let data = user.profileImage else { return nil }
        return UIImage(data: data)
    }
}
