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
        }
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
