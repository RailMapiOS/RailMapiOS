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
                .background(.ultraThinMaterial)
                .toolbar(.hidden, for: .navigationBar)
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
        VStack(spacing: 0) {
            customHeader
            tabContent
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                if store.selectedTab == .search {
                    bottomSearchBar
                }
                CustomTabBarView(selectedTab: Binding(
                    get: { store.selectedTab },
                    set: { store.send(.tabSelected($0)) }
                ))
                .background(.ultraThinMaterial)
            }
        }
    }

    // MARK: - Custom Header (large title + profile button side by side)

    private var customHeader: some View {
        HStack(alignment: .center) {
            // Compact sheet: shrink the title from .title (~28pt) to .headline
            // (~17pt) and tighten paddings — saves ~16pt of vertical space when
            // the sheet is at .fraction(0.3) (~256pt total).
            Text(store.selectedTab.title)
                .font(store.isCompact ? .headline : .title)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer()
            #if DEBUG
            // DEBUG-only: replace the profile button with a menu to seed mock
            // journeys (refund eligible, multi-stop, OUIGO, cancelled, etc.)
            // so we can verify UI states without depending on real GTFS data.
            Menu {
                ForEach(MockJourneyKind.allCases) { kind in
                    Button {
                        store.send(.insertMockJourney(kind))
                    } label: {
                        Label(kind.label, systemImage: kind.systemImage)
                    }
                }
                Divider()
                Button {
                    store.send(.profileButtonTapped)
                } label: {
                    Label("Open profile (real)", systemImage: "person.crop.circle")
                }
            } label: {
                Image(systemName: "ladybug.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.purple)
                    .frame(height: 30)
            }
            #else
            Button { store.send(.profileButtonTapped) } label: {
                profileImage
            }
            .buttonStyle(.plain)
            #endif
        }
        .padding(.horizontal, 20)
        .padding(.top, store.isCompact ? 8 : 12)
        .padding(.bottom, store.isCompact ? 4 : 8)
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

            TextField("Search for a journey...", text: Binding(
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
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Journeys Tab

    private var journeysContent: some View {
        Group {
            if store.shouldShowEmptyState {
                EmptyListJourneyView(compact: store.isCompact)
            } else {
                List {
                    // 1) Active — currently in transit, on time
                    if !store.activeJourneys.isEmpty {
                        Section {
                            journeyRows(store.activeJourneys)
                        } header: {
                            sectionHeader("In transit", systemImage: "tram.fill")
                        }
                    }

                    // 2) Delayed / Cancelled — orange pastille (delay) or red (cancelled)
                    if !store.delayedJourneys.isEmpty {
                        Section {
                            journeyRows(store.delayedJourneys)
                        } header: {
                            sectionHeader("Delayed", systemImage: "clock.badge.exclamationmark.fill")
                        }
                    }

                    // 3) Upcoming — future, not yet active
                    if !store.upcomingJourneys.isEmpty {
                        Section {
                            journeyRows(store.upcomingJourneys)
                        } header: {
                            sectionHeader("Upcoming", systemImage: "calendar")
                        }
                    }

                    // 4) Archived — past, no delay
                    if !store.pastJourneys.isEmpty {
                        Section {
                            journeyRows(store.pastJourneys, dimmed: true)
                        } header: {
                            sectionHeader("Past journeys", systemImage: "clock.arrow.circlepath")
                        }
                    }
                }
                .listStyle(.plain)
                .scrollIndicators(.visible)
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// Derives the badge to overlay on a row from its realtime status.
    /// View-side equivalent of the same-named computation in the reducer
    /// state — kept here because TCA's @ObservableState dynamic-member
    /// lookup forwards properties but not methods.
    private func badge(from status: RealtimeStatus?) -> SavedJourneyBadge? {
        guard let status else { return nil }
        if status.isCancelled { return .cancelled }
        let delaySec = status.arrivalDelaySeconds ?? 0
        guard delaySec >= 60 else { return nil }
        return .delayed(minutes: delaySec / 60)
    }

    /// Common row builder for all 4 priority sections. The badge (delayed
    /// or cancelled) is derived per-journey from the realtime status; rows
    /// in archived sections are dimmed for visual hierarchy.
    @ViewBuilder
    private func journeyRows(_ journeys: [Journey], dimmed: Bool = false) -> some View {
        ForEach(journeys, id: \.persistentModelID) { journey in
            let status = journey.id.flatMap { store.realtimeUpdates[$0] }
            SavedJourneyRow(
                journey: journey,
                realtimeStatus: status
            )
            .overlay(alignment: .topTrailing) {
                if let badge = badge(from: status) {
                    badge.view.padding(8)
                }
            }
            .opacity(dimmed ? 0.65 : 1)
            .onTapGesture { store.send(.journeyTapped(journey)) }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    store.send(.journeyDeleted(journey))
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    // MARK: - Search Tab

    private var searchContent: some View {
        Group {
            if store.searchText.isEmpty {
                placeholderView(
                    icon: "magnifyingglass",
                    title: "Search for a journey",
                    subtitle: "Enter a train number (e.g. 6234, 8541)"
                )
            } else if !store.filteredJourneys.isEmpty || !store.searchResults.isEmpty {
                List {
                    if !store.filteredJourneys.isEmpty {
                        Section {
                            ForEach(store.filteredJourneys, id: \.persistentModelID) { journey in
                                SavedJourneyRow(journey: journey)
                                    .onTapGesture { store.send(.journeyTapped(journey)) }
                            }
                        } header: {
                            sectionHeader("Your journeys", systemImage: "bookmark.fill")
                        }
                    }

                    if !store.searchResults.isEmpty {
                        Section {
                            ForEach(store.searchResults) { result in
                                SearchResultRow(result: result)
                                    .onTapGesture { store.send(.searchResultTapped(result)) }
                            }
                        } header: {
                            sectionHeader("Add a new journey", systemImage: "plus.circle")
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            } else if store.isCompact {
                // Compact sheet: collapse the empty/loading state to a single
                // line that fits between the header and the search bar (~92pt).
                HStack(spacing: 8) {
                    if store.isSearchingAPI {
                        ProgressView().controlSize(.small)
                        Text("Searching…")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.tertiary)
                        Text("No results — check the train number")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 24)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        if store.isSearchingAPI {
                            ProgressView()
                                .padding(.bottom, 8)
                        } else {
                            Image(systemName: "magnifyingglass")
                                .resizable()
                                .foregroundStyle(.tertiary)
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: 60)
                                .padding(.bottom, 8)
                        }
                        Text(store.isSearchingAPI ? "Searching..." : "No results")
                            .font(.title2)
                            .fontWeight(.bold)
                        if !store.isSearchingAPI {
                            Text("Check the train number")
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
                Text("Friends")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Coming soon")
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
                        Text("Sign in")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Sign in to access your profile")
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

    // MARK: - Section Header

    private func sectionHeader(_ title: LocalizedStringResource, systemImage: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption)
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            Spacer()
        }
        .foregroundStyle(.secondary)
        .padding(.vertical, 4)
        .textCase(nil)
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

    private func placeholderView(icon: String, title: LocalizedStringResource, subtitle: LocalizedStringResource) -> some View {
        Group {
            if store.isCompact {
                // Compact sheet: only show the guidance line, centered above the
                // search bar — no icon, no title, just the instruction.
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 24)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        Image(systemName: icon)
                            .resizable()
                            .foregroundStyle(.tertiary)
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 60)
                            .padding(.bottom, 8)
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
    }
}
