//
//  BottomSheetView.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 12/07/2024.
//

import SwiftUI
import CoreData

struct BottomSheetView: View {
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Journey.startDate, ascending: true)]) var journeys: FetchedResults<Journey>
    @State private var path = NavigationPath()
    
    @Binding var sheetSize: PresentationDetent
    @State private var searchText = ""
    @State private var searchPresented: Bool = false {
        didSet {
            if searchPresented {
                sheetSize = .large
            }
        }
    }
    
    //@State private var searchTicket = ""
    
    var filteredJourneys: [Journey] {
        searchText.isEmpty ? Array(journeys) : journeys.filter { $0.headsign?.contains(searchText) ?? false }
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                if searchPresented && filteredJourneys.isEmpty {
                    AddTicketV(searchText: $searchText)
                } else {
                    List(filteredJourneys, id: \.self) { journey in
                        JourneyRowView(journey: journey)
                            .onTapGesture {
                                path.append(journey)
                                if sheetSize != .large || sheetSize != .medium {
                                    sheetSize = .medium
                                }
                            }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationDestination(for: Journey.self) { journey in
                JourneyDetailsV(journey: journey)
                    .ignoresSafeArea(.all, edges: .bottom)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text(searchPresented && filteredJourneys.isEmpty ? "Add a Journey" : "My Journeys")
                        .fontWeight(.bold)
                        .font(.title)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                                        if searchPresented && filteredJourneys.isEmpty {
                    Button(action: {
                        if journeys.isEmpty {
                            let dataController = DataController()
                            dataController.createMockJourneys(context: moc)
                        }
                    }) {
                        Text("Save")
                            .foregroundColor(.blue)
                    }
                                        } else {
                                            Button(action: {
                                                let dataController = DataController()
                                                dataController.createMockJourneys(context: moc)
                                            }) {
                                                Image(systemName: "plus")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                }
            }
            .searchable(text: $searchText, isPresented: $searchPresented, placement: .navigationBarDrawer(displayMode: .always))
            .searchPresentationToolbarBehavior(.avoidHidingContent)
        }
    }
}

#Preview {
    let context = NSPersistentContainer.preview.viewContext
    return BottomSheetView(sheetSize: .constant(.medium))
        .environment(\.managedObjectContext, context)
}
