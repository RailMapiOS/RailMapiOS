//
//  JourneyRowView.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 12/07/2024.
//

import CoreData
import SwiftUI

struct JourneyRowView: View {
    @ObservedObject var viewModel: JourneyRowViewModel
    
    init(journey: Journey) {
        self.viewModel = JourneyRowViewModel(journey: journey)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Spacer()
                Text(viewModel.departureTime)
                    .font(.title)
                    .fontWeight(.semibold)
                Text(viewModel.departureDate)
                    .font(.title3)
                Spacer()
                Text("Total \(viewModel.duration)")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
            }
            .frame(alignment: .leading)
            
            Divider()
            
            VStack {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Gare de")
                            .font(.title3)
                        Text(viewModel.departureLabel.replacingOccurrences(of: "Gare de ", with: ""))
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    Spacer()
                    Image(systemName: "train.side.front.car")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20.0)
                        .foregroundColor(.blue)
                        .padding(.all, 3)
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Gare de")
                            .font(.title3)
                        Text(viewModel.arrivalLabel.replacingOccurrences(of: "Gare de ", with: ""))
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
                
                HStack {
                    Text(viewModel.departureTime)
                        .font(.caption2)
                        .fontWeight(.bold)
                    
                    VStack {
                        Divider().frame(maxWidth: 50)
                    }
                    
                    Text(viewModel.headsign)
                        .font(.caption2)
                    VStack {
                        Divider().frame(maxWidth: 50)
                    }
                    
                    Text(viewModel.arrivalTime)
                        .font(.caption2)
                        .fontWeight(.bold)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8.0)
    }
}

#Preview {
    let context = NSPersistentContainer.preview.viewContext
    let fetchRequest: NSFetchRequest<Journey> = Journey.fetchRequest()
    fetchRequest.fetchLimit = 1
    
    guard let journey = try? context.fetch(fetchRequest).first else {
        fatalError("Aucun voyage trouvé pour la prévisualisation.")
    }
    
    return JourneyRowView(journey: journey)
        .environment(\.managedObjectContext, context)
}
