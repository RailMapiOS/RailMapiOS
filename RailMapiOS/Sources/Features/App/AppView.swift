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
    /// The sheet's own frame, in global coordinates. `MapView` turns it into the
    /// obscured edge so the camera frames the visible area — above the sheet on a
    /// bottom placement, beside it when iOS 27 puts it on the trailing edge. It
    /// is measured rather than assumed: the system resolves
    /// `presentationPlacement(.trailing)` differently depending on how much room
    /// the layout has, so a portrait iPhone still gets a bottom sheet.
    @State private var sheetFrame: CGRect = .zero

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
            MapView(store: store.scope(state: \.map, action: \.map), sheetFrame: sheetFrame)
            .edgesIgnoringSafeArea(.all)
            .sheet(isPresented: $isSheetPresented) {
              if #available(anyAppleOS 27.0, *) {
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
                  .presentationPlacement(.trailing)
                  .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { sheetFrame = $0 }
              } else {
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
                  .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { sheetFrame = $0 }
              }
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
