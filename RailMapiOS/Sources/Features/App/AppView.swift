//
//  AppView.swift
//  RailMapiOS
//

import ComposableArchitecture
import MapKit
import SwiftData
import SwiftUI

struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>
    @Query(sort: \Journey.startDate) var journeys: [Journey]
    @State private var isSheetPresented = true

    var body: some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .phone {
                iPhoneLayout
            } else {
                iPadLayout
            }
        }
        .onChange(of: journeys.compactMap(\.id)) { _, _ in
            store.send(.journeysLoaded(journeys))
        }
        .onAppear {
            store.send(.journeysLoaded(journeys))
        }
    }

    // MARK: - iPhone

    private var iPhoneLayout: some View {
        ZStack {
            MapView(store: store.scope(state: \.map, action: \.map))
            .edgesIgnoringSafeArea(.all)
            .sheet(isPresented: $isSheetPresented) {
                journeysSheet
                    .trailingSheetPlacementIfAvailable()
            }
        }
    }

    /// The sheet itself. The only thing that varies by OS is where the system
    /// places it, so the placement is a modifier rather than a second copy of
    /// this whole builder.
    private var journeysSheet: some View {
        BottomSheetView(store: store.scope(state: \.bottomSheet, action: \.bottomSheet))
            .presentationDetents(
                store.bottomSheet.availableDetents,
                selection: Binding(
                    get: { store.bottomSheet.sheetSize },
                    set: { store.send(.bottomSheet(.sheetSizeChanged($0))) }
                )
            )
            .presentationBackgroundInteraction(.enabled(upThrough: .large))
            .presentationBackground(.clear)
            .presentationCornerRadius(nil)
            .interactiveDismissDisabled()
    }

    // MARK: - iPad

    private var iPadLayout: some View {
        NavigationSplitView {
            BottomSheetView(store: store.scope(state: \.bottomSheet, action: \.bottomSheet))
                .frame(minWidth: 200)
        } detail: {
            MapView(store: store.scope(state: \.map, action: \.map))
                .edgesIgnoringSafeArea(.all)
        }
    }
}

// MARK: - Sheet placement

private extension View {
    /// Asks iOS to put the sheet against the trailing edge, where it can.
    ///
    /// Double-gated on purpose:
    ///
    /// - `#if compiler(>=6.4)` because `presentationPlacement` does not exist in
    ///   Xcode 26.6's SwiftUI. `#available` alone is a *runtime* check; the
    ///   symbol still has to resolve at compile time, so referencing it there
    ///   fails the build outright — which is what stopped 26.6 from compiling
    ///   this file, and 26.6 is the toolchain the TestFlight archives come from
    ///   while Xcode 27 is in beta. Swift 6.4 ships with Xcode 27, 6.3.3 with 26.6.
    /// - `#available(iOS 27.0, *)` because the app still runs on iOS 18.
    ///
    /// The system may decline: on a portrait iPhone it resolves this to a bottom
    /// sheet, verified on the iOS 27.0 simulator. That is why the map measures
    /// the sheet's frame instead of assuming an edge from the OS version — see
    /// `MapObscuredInsets`.
    @ViewBuilder
    func trailingSheetPlacementIfAvailable() -> some View {
        #if compiler(>=6.4)
        if #available(iOS 27.0, *) {
            presentationPlacement(.trailing)
        } else {
            self
        }
        #else
        self
        #endif
    }
}
