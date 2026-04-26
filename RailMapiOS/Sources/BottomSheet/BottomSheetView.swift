//
//  BottomSheetView.swift
//  RailMapiOS
//

import ComposableArchitecture
import SwiftUI

struct BottomSheetView: View {
    @Bindable var store: StoreOf<BottomSheetFeature>

    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            contentWithBars
                .navigationTitle(store.selectedTab.title)
                .navigationBarTitleDisplayMode(.inline)
                .sheet(item: $store.scope(state: \.signIn, action: \.signIn)) { signInStore in
                    SignInView(store: signInStore)
                }
                .sheet(item: $store.scope(state: \.account, action: \.account)) { accountStore in
                    AccountView(store: accountStore)
                }
        } destination: { store in
            switch store.case {
            case .journeyDetail(let detailStore):
                JourneyDetailView(store: detailStore)
            case .stationPicker(let pickerStore):
                StationPickerView(store: pickerStore)
            case .datePicker(let dateStore):
                DatePickerView(store: dateStore)
            case .confirmation(let confirmStore):
                ConfirmationView(store: confirmStore)
            }
        }
        .accessibilityIdentifier(AccessibilityID.BottomSheetView.navigationStack)
    }

    // MARK: - Content with Bars

    @ViewBuilder
    private var contentWithBars: some View {
        tabContent
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    if store.selectedTab == .search {
                        bottomSearchBar
                    }
                    CustomTabBarView(selectedTab: Binding(
                        get: { store.selectedTab },
                        set: { store.send(.tabSelected($0)) }
                    ))
                }
                .background(.regularMaterial)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { store.send(.profileButtonTapped) } label: {
                        profileImage
                    }
                }
            }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch store.selectedTab {
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

    // MARK: - Search Bar

    private var bottomSearchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.system(size: 16))

            TextField("Rechercher un trajet...", text: Binding(
                get: { store.searchText },
                set: { store.send(.searchTextChanged($0)) }
            ))
            .textFieldStyle(.plain)
            .font(.body)
            .submitLabel(.search)

            if !store.searchText.isEmpty {
                Button { store.send(.searchTextChanged("")) } label: {
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
            if store.shouldShowEmptyState {
                EmptyListJourneyView(compact: store.isCompact)
            } else {
                List(store.filteredJourneys, id: \.id) { journey in
                    JourneyRowView(journey: journey)
                        .onTapGesture { store.send(.journeyTapped(journey)) }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                store.send(.journeyDeleted(journey))
                            } label: {
                                Label("Supprimer", systemImage: "trash")
                            }
                        }
                }
                .listStyle(.plain)
                .scrollIndicators(.visible)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Search Tab

    private var searchContent: some View {
        Group {
            if store.searchText.isEmpty {
                placeholderView(
                    icon: "magnifyingglass",
                    title: "Rechercher un trajet",
                    subtitle: "Entrez un numéro de train"
                )
            } else if !store.filteredJourneys.isEmpty {
                List(store.filteredJourneys, id: \.id) { journey in
                    JourneyRowView(journey: journey)
                        .onTapGesture { store.send(.journeyTapped(journey)) }
                }
                .listStyle(.plain)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        if store.isSearchingAPI {
                            ProgressView()
                                .padding(.bottom, 8)
                        } else if !store.isCompact {
                            Image(systemName: "magnifyingglass")
                                .resizable()
                                .foregroundStyle(.tertiary)
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: 60)
                                .padding(.bottom, 8)
                        }
                        Text(store.isSearchingAPI ? "Recherche..." : "Entrez un numéro de train")
                            .font(.title2)
                            .fontWeight(.bold)
                        if !store.isSearchingAPI {
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

    // MARK: - Friends Tab

    private var friendsContent: some View {
        ScrollView {
            VStack(spacing: 12) {
                if !store.isCompact {
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
                if store.isUserLoggedIn, let user = UserStorage.shared.currentUser {
                    VStack(spacing: 12) {
                        if let data = user.profileImage, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable().scaledToFit()
                                .frame(width: 80, height: 80).clipShape(.circle)
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable().scaledToFit()
                                .frame(width: 80, height: 80).foregroundStyle(.secondary)
                        }
                        Text("\(user.firstName) \(user.lastName)")
                            .font(.title2).fontWeight(.bold)
                        if let email = user.email {
                            Text(email).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        if !store.isCompact {
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
                            store.send(.profileButtonTapped)
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

    // MARK: - Profile Image

    private var profileImage: some View {
        Group {
            if store.isUserLoggedIn,
               let user = UserStorage.shared.currentUser,
               let data = user.profileImage,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 30)
                    .clipShape(.circle)
            } else if store.isUserLoggedIn {
                Image(systemName: "person.crop.circle.fill.badge.checkmark")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 30)
            } else {
                Image(systemName: "person.crop.circle.fill.badge.plus")
                    .resizable()
                    .foregroundStyle(.gray)
                    .scaledToFit()
                    .frame(height: 30)
            }
        }
    }

    // MARK: - Helpers

    private func placeholderView(icon: String, title: String, subtitle: String) -> some View {
        ScrollView {
            VStack(spacing: 12) {
                if !store.isCompact {
                    Image(systemName: icon)
                        .resizable()
                        .foregroundStyle(.tertiary)
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 60)
                        .padding(.bottom, 8)
                }
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 16)
        }
    }
}
