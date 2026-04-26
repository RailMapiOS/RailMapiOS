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
            MapView(store: store.scope(state: \.map, action: \.map), sheetSize: store.sheetSize)
                .edgesIgnoringSafeArea(.all)
                .sheet(isPresented: $isSheetPresented) {
                    BottomSheetView(store: store.scope(state: \.bottomSheet, action: \.bottomSheet))
                        .presentationDetents(
                            [.fraction(0.3), .medium, .large],
                            selection: Binding(
                                get: { store.sheetSize },
                                set: { store.send(.sheetSizeChanged($0)) }
                            )
                        )
                        .presentationBackgroundInteraction(.enabled(upThrough: .large))
                        .presentationBackground(.ultraThinMaterial)
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
            MapView(store: store.scope(state: \.map, action: \.map), sheetSize: .large)
                .edgesIgnoringSafeArea(.all)
        }
    }
}
