//
//  JourneyRowView.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 12/07/2024.
//

import CoreData
import SwiftUI

struct JourneyRowView: View {
    @StateObject private var viewModel: JourneyRowViewModel
    
    init(journey: Journey) {
        self._viewModel = StateObject(
            wrappedValue: JourneyRowViewModel(
                journey: journey
            )
        )
    }
    
    var body: some View {
        ZStack {
            VStack {
                JourneyRowHeader(
                    company: viewModel.compagny,
                    headsign: viewModel.headsign,
                    duration: viewModel.duration
                )
                
                JourneyTimes(
                    departureTime: viewModel.departureTime,
                    departureLabel: viewModel.departureLabel,
                    arrivalTime: viewModel.arrivalTime,
                    arrivalLabel: viewModel.arrivalLabel
                )
                
                DashedDivider()
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [5, 3]))
                    .frame(height: 1)
                    .opacity(0.2)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 10)
                
                JourneyRowFooter(
                    departureDate: viewModel.departureDate
                )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8.0)
        }
        .listRowBackground(Color.clear)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.10), radius: 8, y: 2)
        .padding(.horizontal, 8)
    }
}

//#Preview {
//    let context = NSPersistentContainer.preview.viewContext
//    let fetchRequest: NSFetchRequest<Journey> = Journey.fetchRequest()
//    fetchRequest.fetchLimit = 1
//    
//    guard let journey = try? context.fetch(fetchRequest).first else {
//        fatalError("Aucun voyage trouvé pour la prévisualisation.")
//    }
//}
