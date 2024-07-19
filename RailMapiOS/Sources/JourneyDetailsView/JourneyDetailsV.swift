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
        LazyVStack {
            //Departure
            VStack {
                HStack {
                    Text("Gare de Lyon")
                        .multilineTextAlignment(.leading)
                        .fontWeight(.semibold)
                        .font(.title2)
                    Spacer()
                    Text(dateFormatter(for:journey.startDate))
                        .fontWeight(.semibold)
                        .font(.title2)
                }
            }
            HStack {
                VStack{
                    Divider()
                }
                Text("Total \(calculateDurationString(from: journey.startDate!, to: journey.endDate!))")
                VStack{
                    Divider()
                }
            }
            //Arrival
            VStack {
                HStack {
                    Text("Gare de Perpignan")
                        .multilineTextAlignment(.leading)
                        .fontWeight(.semibold)
                        .font(.title2)
                    Spacer()
                    Text(dateFormatter(for: journey.endDate))
                        .multilineTextAlignment(.trailing)
                        .fontWeight(.semibold)
                        .font(.title2)
                }
            }
        }
    }
    
    func dateFormatter(for date: Date?) -> String {
        guard let date = date else {
            return "Date non disponible"
        }
        
        let dateFormatter = DateFormatter()
        
        // Configurer le format de la date
        dateFormatter.dateFormat = "HH:mm\ndd MMMM"
        
        // Convertir la date en chaîne
        return dateFormatter.string(from: date)
    }
    
    func calculateDurationString(from startDate: Date, to endDate: Date) -> String {
        let interval = endDate.timeIntervalSince(startDate) // Durée en secondes
        
        // Convertir les secondes en heures et minutes
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        
        // Formater la chaîne de caractères
        return String(format: "%02dh%02d", hours, minutes)
    }
}

#Preview {
    let container = NSPersistentContainer.preview
           let context = container.viewContext
           
           // Création de données fictives pour la prévisualisation
           let dataController = DataController()
           dataController.createMockJourneys(context: context)
           
           // Récupération d'un voyage fictif pour la prévisualisation
           let fetchRequest: NSFetchRequest<Journey> = Journey.fetchRequest()
           fetchRequest.fetchLimit = 1
           
           guard let journey = try? context.fetch(fetchRequest).first else {
               fatalError("Aucun voyage trouvé pour la prévisualisation.")
           }
           
           return JourneyDetailsV(journey: journey)
               .environment(\.managedObjectContext, context)
}
