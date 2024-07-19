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
    
    @State private var isSheetPresented = true
    @State private var sheetSize: PresentationDetent = .fraction(0.3)
    
    public var body: some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .phone {
                iPhoneLayout(isSheetPresented: $isSheetPresented, sheetSize: $sheetSize)
            } else {
                iPadLayout(sheetSize: $sheetSize)
            }
        }
    }
}

public struct iPhoneLayout: View {
    @Binding var isSheetPresented: Bool
    @Binding var sheetSize: PresentationDetent

    public var body: some View {
        ZStack {
            Map()
                .sheet(isPresented: $isSheetPresented) {
                    BottomSheetView(sheetSize: $sheetSize)
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

    public var body: some View {
        NavigationSplitView {
            BottomSheetView(sheetSize: $sheetSize)
                .listStyle(SidebarListStyle())
                .frame(minWidth: 200)
        } detail: {
            Map()
                .edgesIgnoringSafeArea(.all)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
