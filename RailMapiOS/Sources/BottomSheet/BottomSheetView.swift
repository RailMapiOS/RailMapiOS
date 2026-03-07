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
            contentView
                .navigationTitle("My Journeys")
                .navigationBarTitleDisplayMode(.inline)
                .searchable(
                    text: searchTextBinding,
                    isPresented: searchPresentedBinding,
                    prompt: "Search journeys..."
                )
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewModel.processIntent(viewModel.isUserLoggedIn ? .toggleAccount : .toggleSignIn)
                        } label: {
                            userProfileImage
                        }
                        .buttonStyle(.plain)
                    }
                }
                .navigationDestination(for: Router.Flow.self, destination: navigationDestination)
                .sheet(item: $router.activeSheet) { sheetType in
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
                        mapSettings.clearRouteSelection()
                    }
                }
        }
        .accessibilityIdentifier(AccessibilityID.BottomSheetView.navigationStack)
    }

    // MARK: - Content

    private var contentView: some View {
        Group {
            if viewModel.state.shouldShowAddTicket {
                AddTicketView(
                    router: router,
                    searchText: searchTextBinding
                )
            } else if viewModel.state.shouldShowEmptyState {
                EmptyListJourneyView()
            } else {
                journeyListView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
        StationPickerView(viewModel: StationPickerViewModel(pickedJourney: selectedDateRow)) { pickedJourney in
            router.navigate(to: .confirmation(pickedJourney))
        }
    }

    private func confirmationView(for pickedJourney: DateRow) -> some View {
        ConfirmationPickerView(viewModel: ConfirmationPickerViewModel(pickedJourney: pickedJourney, dataController: dataController)) {
            router.navigateToRoot()
        }
    }

    private func datePickerView(for dateRows: [DateRow]) -> some View {
        DatePickerView(viewModel: DatePickerViewModel(dateRows: dateRows), router: router) { selectedRow in
            router.navigate(to: .stationPicker(selectedRow))
        }
    }
}
