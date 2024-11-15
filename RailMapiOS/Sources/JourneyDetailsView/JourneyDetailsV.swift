//
//  JourneyDetailsV.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 19/07/2024.
//

import SwiftUI
import CoreData

struct JourneyDetailsV: View {
    @State var journey: Journey
    
    var body: some View {
        JourneyHeaderView(company: journey.company,
                          headsign: journey.headsign,
                          departureCity: "Paris",
                          arrivalCity: "Perpignan",
                          departureDate: journey.startDate,
                          size: CGSize(width: 60, height: 60))
        
        VStack(spacing: 0) {
            Divider()
            ScrollView(showsIndicators: true) {
                VStack{
                    StationView(stationLabel: "Gare de Lyon", date: journey.startDate!, arrival: false)
                    DurationView(startDate: journey.startDate, endDate: journey.endDate)
                    StationView(stationLabel: "Gare de Perpignan", date: journey.endDate!, arrival: true)
                }
                .padding(.vertical)
                Divider()
                
                LazyVStack(alignment: .leading) {
                    Text("Détail du voyage")
                        .font(.headline)
                    
                    if let sations = journey.stops?.allObjects as? [Stop]{
                        ForEach(sations, id: \.self) { station in
                            VerticalTimeline(
                                timelineConfig: .trip,
                                stationLabel: (station.stopinfo?.label)!,
                                timeLabel: station.departureTimeUTC!.description)
                            //                        StationView(stationLabel: station.label, date: station.date)
                            Spacer()
                        }
                        .padding()
                    }
                    //                } else {
                    //                    Text("Aucune station disponible.")
                    //                        .font(.subheadline)
                    //            }
                    Spacer()
                }
                .padding(.vertical)
                Spacer()
            }
        }
    }
}

#Preview {
    let container = NSPersistentContainer.preview
    let context = container.viewContext
    
    let dataController = DataController()
    dataController.createMockJourneys(context: context)
    
    let fetchRequest: NSFetchRequest<Journey> = Journey.fetchRequest()
    fetchRequest.fetchLimit = 1
    
    guard let journey = try? context.fetch(fetchRequest).first else {
        fatalError("Aucun voyage trouvé pour la prévisualisation.")
    }
    
    return JourneyDetailsV(journey: journey)
        .environment(\.managedObjectContext, context)
}
