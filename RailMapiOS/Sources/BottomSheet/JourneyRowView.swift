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
        VStack {
            
            HStack{
                
                Image("icon_\(viewModel.compagny.lowercased().replacingOccurrences(of: " ", with: ""))")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 40, maxHeight: 40)
                    .clipShape(.circle)
                    .padding(.horizontal, 10)
                
                VStack(alignment: .leading) {
                    Text(viewModel.compagny)
                    Text(viewModel.headsign)
                        .font(.caption2)
                        .foregroundStyle(.gray)
                }
                Spacer()
                
                Image(systemName: "clock.fill")
                    .foregroundStyle(.gray)
                    .aspectRatio(CGSize(width: 10, height: 10), contentMode: .fit)
                    .opacity(0.5)
                
                Text(viewModel.duration)
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }
            
            HStack {
                VStack {
                    Text(viewModel.departureTime)
                        .font(.title2)
                    Text(viewModel.departureLabel)
                        .font(.subheadline)
                }
                Spacer()
                Image(systemName: "train.side.front.car")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20.0)
                    .foregroundColor(.blue)
                    .padding(.all, 3)
                    .padding(.bottom, 4)
                Spacer()
                VStack {
                    Text(viewModel.arrivalTime)
                        .font(.title2)
                    Text(viewModel.arrivalLabel)
                        .font(.subheadline)
                }
            }
            DashedDivider()
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [5, 3]))
                .frame(height: 1)
                .opacity(0.2)
                .foregroundColor(.gray)
                .padding(.horizontal, 10)
            HStack {
                Text(viewModel.departureDate)
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                
                Spacer()
                
                Text("Direct")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
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
