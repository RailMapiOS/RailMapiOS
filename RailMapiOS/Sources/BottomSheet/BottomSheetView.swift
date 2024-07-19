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
    @FetchRequest(sortDescriptors: []) var journeys: FetchedResults<Journey>
    @State private var path = NavigationPath()
    var mocks: [String] = ["A", "B", "C"]
    
    @Binding var sheetSize: PresentationDetent
    @State private var searchText = ""
    @State private var searchPresented: Bool = false {
        didSet {
            if searchPresented {
                sheetSize = .large
            }
        }
    }
    
    @State private var searchTicket = "" // Variable for searching a train journey online to add a new ticket
    
    var filteredJourneys: [Journey] {
        searchText.isEmpty ? Array(journeys) : journeys.filter { $0.headsign?.contains(searchText) ?? false }
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                if searchPresented && filteredJourneys.isEmpty {
                    AddTicketV(searchText: $searchTicket)
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
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text(searchPresented && filteredJourneys.isEmpty ? "Add a Journey" : "My Journeys")
                        .fontWeight(.bold)
                        .font(.title)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
//                    if searchPresented && filteredJourneys.isEmpty {
                        Button(action: {
                            if journeys.isEmpty {
                                let dataController = DataController()
                                                            dataController.createMockJourneys(context: moc)
                            }
                        }) {
                            Text("Save")
                                .foregroundColor(.blue)
                        }
//                    } else {
//                        Button(action: {
//                            DataController.shared.createMockJourneys(context: moc)
//                        }) {
//                            Image(systemName: "plus")
//                                .foregroundColor(.blue)
//                        }
//                    }
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
