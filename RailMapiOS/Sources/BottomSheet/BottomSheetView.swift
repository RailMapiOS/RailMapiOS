//
//  BottomSheetView.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 12/07/2024.
//

import SwiftUI
import CoreData
import AuthenticationServices

struct BottomSheetView: View {
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Journey.startDate, ascending: true)]) var journeys: FetchedResults<Journey>
    @ObservedObject var router: Router

    @State var isUserLogin: Bool = false
    @State var showSignIn: Bool = false
    
    @Binding var sheetSize: PresentationDetent
    @State private var searchText = ""
    @State private var searchPresented: Bool = false {
        didSet {
            if searchPresented {
                sheetSize = .large
            }
        }
    }
        
    var filteredJourneys: [Journey] {
        searchText.isEmpty ? Array(journeys) : journeys.filter { $0.headsign?.contains(searchText) ?? false }
    }
    
    var body: some View {
        NavigationStack(path: $router.path) {
            VStack {
                if searchPresented && filteredJourneys.isEmpty {
                    AddTicketV(router: router, searchText: $searchText)
                        .padding(.top)
                } else if !searchPresented && filteredJourneys.isEmpty {
                    EmptyListJourneyView()
                } else {
                    List(filteredJourneys, id: \.objectID) { journey in
                        JourneyRowView(journey: journey)
                            .onTapGesture {
                                withAnimation {
                                    router.navigate(to: .journeyDetails(objectID: journey.objectID))
                                    updateSheetSize()
                                }
                            }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationDestination(for: Router.Flow.self) { flow in
                switch flow {
                case .journeys:
                    Text("My Journeys")
                case .addTicket(let searchText):
                    AddTicketV(router: router, searchText: .constant(searchText ?? ""))
                case .journeyDetails(let objectID):
                    if let journey = moc.object(with: objectID) as? Journey {
                        JourneyDetailsV(journey: journey)
                    } else {
                                Text("Journey not found")
                            }
                case .stationPicker(let selectedDateRow):
                    StationPickerView(viewModel: StationPickerViewModel(pickedJourney: selectedDateRow)) { pickedJourney in
                        router.navigate(to: .confirmation(pickedJourney))
                    }
                case .confirmation(let pickedJourney):
                    ConfirmationPickerView(viewModel: ConfirmationPickerViewModel(pickedJourney: pickedJourney, dataController: dataController)) {
                        router.navigateToRoot()
                    }
                case .datePicker(let dateRows):
                    DatePickerView(viewModel: DatePickerViewModel(dateRows: dateRows), router: router) { selectedRow in
                        router.navigate(to: .stationPicker(selectedRow))
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text(searchPresented && filteredJourneys.isEmpty ? "Add a Journey" : "My Journeys")
                        .fontWeight(.bold)
                        .font(.title)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSignIn.toggle()
                            
                    } label: {
                        switch self.isUserLogin {
                        case true:
                            Image(systemName: "person.crop.circle.fill.badge.checkmark")
                        case false:
                            Image(systemName: "person.crop.circle.fill.badge.plus")
                                .foregroundStyle(.gray)
                        }
                       
                    }
                }
            }
            .searchable(text: $searchText, isPresented: $searchPresented, placement: .navigationBarDrawer(displayMode: .always))
            .searchPresentationToolbarBehavior(.avoidHidingContent)
            .sheet(isPresented: $showSignIn) {
                SignInView()
            }
        }
    }
    
    private func updateSheetSize() {
        switch sheetSize {
        case .large, .medium:
            sheetSize = .large
        default:
            sheetSize = .medium
        }
    }
}
