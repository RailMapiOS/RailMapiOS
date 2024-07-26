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
            headerView
            Divider()
            stationView(stationLabel: "Gare de Lyon" , date: journey.startDate!)
            durationView
            stationView(stationLabel: "Gare de Perpignan" , date: journey.endDate!)
            Divider()
        }
    }
    
    private var headerView: some View {
        HStack {
            companyLogo
            Spacer()
            journeyInfo
        }
        .padding(.horizontal)
    }
    
    private var companyLogo: some View {
        VStack(alignment: .leading) {
            if let company = journey.company {
                Image("logo_\(company.lowercased().replacingOccurrences(of: " ", with: ""))")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 120, maxHeight: 60)
            }
        }
    }
    
    private var journeyInfo: some View {
        VStack(alignment: .trailing) {
            if let headsign = journey.headsign, let company = journey.company {
                Text(headsign)
                    .font(.title3)
                Text(company)
                    .font(.subheadline)
            }
        }
    }
    
    private func stationView(stationLabel: String, date: Date) -> some View {
        let (timeString, dateString) = dateFormatter(for: date)
        return VStack {
            HStack(alignment: .center) {
                Text(stationLabel)
                    .multilineTextAlignment(.leading)
                    .fontWeight(.semibold)
                    .font(.title2)
                Spacer()
                VStack(alignment: .trailing) {
                    Text(timeString)
                        .fontWeight(.semibold)
                        .font(.title2)
                    Text(dateString)
                        .font(.subheadline)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }
    
    private var durationView: some View {
        HStack {
            VStack {
                Divider()
            }
            Text("Total \(calculateDurationString(from: journey.startDate, to: journey.endDate))")
            VStack {
                Divider()
            }
        }
        .padding(.horizontal)
    }
    
    func dateFormatter(for date: Date?) -> (String, String) {
        guard let date = date else {
            return ("Heure non disponible", "Date non disponible")
        }
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMMM"
        
        let timeString = timeFormatter.string(from: date)
        let dateString = dateFormatter.string(from: date)
        
        return (timeString, dateString)
    }
    
    func calculateDurationString(from startDate: Date?, to endDate: Date?) -> String {
        guard let startDate = startDate, let endDate = endDate else {
            return "Durée non disponible"
        }
        
        let interval = endDate.timeIntervalSince(startDate)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
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
