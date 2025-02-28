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
    
    @StateObject private var router = Router()
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Journey.startDate, ascending: true)])
     var journeys: FetchedResults<Journey>

    public var body: some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .phone {
                iPhoneLayout(
                    isSheetPresented: $isSheetPresented,
                    sheetSize: $sheetSize,
                    router: router,
                    journeys: journeys
                )
            } else {
                iPadLayout(
                    sheetSize: $sheetSize,
                    router: router,
                    journeys: journeys
                )
            }
        }
        .onAppear() {
           // dataController.deleteAllObjects(of: "Journey", context: moc)
        }
    }
}

public struct iPhoneLayout: View {
    @EnvironmentObject var dataController: DataController
    @StateObject private var mapSettings = MapSettings()
    @State private var trainRoutes: [[CLLocationCoordinate2D]] = [
        // Premier trajet (Brussels - Marseille)
        [
         CLLocationCoordinate2D(latitude: 50.83616988703055, longitude: 4.335483297433536),
         CLLocationCoordinate2D(latitude: 50.63962876830489, longitude: 3.0758565720844655),
         CLLocationCoordinate2D(latitude: 49.85935120733636, longitude: 2.831862205872786),
         CLLocationCoordinate2D(latitude: 49.00466837526862, longitude:  2.5709350916955334),
         CLLocationCoordinate2D(latitude: 48.87090463988186, longitude: 2.7825787628084324),
         CLLocationCoordinate2D(latitude: 45.76176168732218, longitude:  4.861342382705875),
         CLLocationCoordinate2D(latitude: 44.9920085607806, longitude:  4.979379568318111),
         CLLocationCoordinate2D(latitude: 43.92206346846921, longitude: 4.786077205405884),
         CLLocationCoordinate2D(latitude: 43.30358452892025,  longitude:  5.381086192493661)
        ],
        // Deuxième trajet (Marseille - Nice)
//        [
//            CLLocationCoordinate2D(latitude: 43.2965, longitude: 5.3698),
//            CLLocationCoordinate2D(latitude: 43.5, longitude: 6.0),
//            CLLocationCoordinate2D(latitude: 43.7031, longitude: 7.2661)
//        ]
    ]

    @Binding var isSheetPresented: Bool
    @Binding var sheetSize: PresentationDetent
    @ObservedObject var router: Router
    let journeys: FetchedResults<Journey>

    public var body: some View {
        ZStack {
            MapView(sheetSize: $sheetSize, journeys: journeys)
                .edgesIgnoringSafeArea(.all)
                .sheet(isPresented: $isSheetPresented) {
                    BottomSheetView(journeys: journeys, router: router, sheetSize: $sheetSize)
                        .padding(.top)
                        .presentationDetents([.fraction(0.3), .medium, .large], selection: $sheetSize)
                        .presentationBackgroundInteraction(.enabled)
                        .interactiveDismissDisabled()
                        .ignoresSafeArea()
                }
        }
    }
}


public struct iPadLayout: View {
    @Binding var sheetSize: PresentationDetent
    @ObservedObject var router: Router
    let journeys: FetchedResults<Journey>

    public var body: some View {
        NavigationSplitView {
            BottomSheetView(journeys: journeys, router: router, sheetSize: $sheetSize)
                .listStyle(SidebarListStyle())
                .frame(minWidth: 200)
        } detail: {
            MapView(sheetSize: $sheetSize, journeys: journeys)
                .edgesIgnoringSafeArea(.all)
        }
    }
}
