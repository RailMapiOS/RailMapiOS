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
        VStack {
            JourneyHeaderView(company: journey.company, headsign: journey.headsign, size: CGSize(width: 60, height: 60))
            Divider()
            StationView(stationLabel: journey.departureStop.stop, date: journey.startDate!)
            DurationView(startDate: journey.startDate, endDate: journey.endDate)
            StationView(stationLabel: "Gare de Perpignan", date: journey.endDate!)
            Divider()
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
