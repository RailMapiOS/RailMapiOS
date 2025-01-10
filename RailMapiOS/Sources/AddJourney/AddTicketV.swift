//
//  AddTicketV.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 19/07/2024.
//

import SwiftUI

struct AddTicketV: View {
    @StateObject var viewModel = AddTicketVM()

    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var moc
    
    private var fetchedJourneys: [VehicleJourney]? {
        if self.viewModel.vehicleJourneys.isEmpty {
            return nil
        } else {
            return self.viewModel.vehicleJourneys
        } }
    
    @Binding var searchText: String
    
    var body: some View {
        
        ScrollView {
            if let journeys = self.fetchedJourneys {
                LazyVStack {
                    Text("Test")
                    Text(journeys.description)
                }
            } else {
                LazyVStack {
                    Text("Add Ticket")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("No journeys found")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Try searching for another journey or add a new one.")
                        .multilineTextAlignment(.center)
                        .padding()
                }

            }
        }
        .onChange(of: searchText) { newValue in
            Task {
                await viewModel.fetchHeadsignAddTicket(headsign: newValue)
            }
        }
    }
}

#Preview {
    @State var searchText: String = "6193"
    return AddTicketV(searchText: $searchText)
}
