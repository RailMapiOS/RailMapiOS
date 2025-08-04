//
//  ContentView.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 12/07/2024.
//

import SwiftUI
import MapKit

public struct ContentView: View {
    public init() {}
    
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    
    @State private var isSheetPresented = true
    @State private var sheetSize: PresentationDetent = .fraction(0.3)
    
    @StateObject private var mapSettings = MapSettings()

    @EnvironmentObject private var router: Router
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Journey.startDate, ascending: true)])
     var journeys: FetchedResults<Journey>

    public var body: some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .phone {
                LayoutiPhone(
                    isSheetPresented: $isSheetPresented,
                    sheetSize: $sheetSize,
                    router: router,
                    mapSettings: mapSettings,
                    journeys: journeys
                )
            } else {
                LayoutiPad(
                    sheetSize: $sheetSize,
                    router: router,
                    mapSettings: mapSettings,
                    journeys: journeys
                )
            }
        }
        .onAppear() {
            dataController.connectMapSettings(mapSettings)        }
    }
}

public struct LayoutiPhone: View {
    @EnvironmentObject var dataController: DataController
    @Binding var isSheetPresented: Bool
    @Binding var sheetSize: PresentationDetent
    @ObservedObject var router: Router
    @ObservedObject var mapSettings: MapSettings
    let journeys: FetchedResults<Journey>

    public var body: some View {
        ZStack {
            MapView(
                sheetSize: $sheetSize,
                mapSettings: mapSettings
            )
                .edgesIgnoringSafeArea(.all)
                .sheet(isPresented: $isSheetPresented) {
                    BottomSheetView(
                        journeys: journeys,
                        router: router,
                        mapSettings: mapSettings,
                        sheetSize: $sheetSize,
                        dataController: dataController
                    )
                        .padding(.top)
                        .presentationDetents([.fraction(0.3), .medium, .large], selection: $sheetSize)
                        .presentationBackgroundInteraction(.enabled(upThrough: .large))
                        .presentationBackground(.ultraThickMaterial)
                        .interactiveDismissDisabled()
                }
        }
    }
}

public struct LayoutiPad: View {
    @EnvironmentObject var dataController: DataController
    @Binding var sheetSize: PresentationDetent
    @ObservedObject var router: Router
    @ObservedObject var mapSettings: MapSettings
    let journeys: FetchedResults<Journey>

    public var body: some View {
        NavigationSplitView {
            BottomSheetView(
                journeys: journeys,
                router: router,
                mapSettings: mapSettings,
                sheetSize: $sheetSize,
                dataController: dataController
            )
                .listStyle(SidebarListStyle())
                .frame(minWidth: 200)
        } detail: {
            MapView(
                sheetSize: $sheetSize,
                mapSettings: mapSettings
            )
                .edgesIgnoringSafeArea(.all)
        }
    }
}
