//
//  JourneyRowView.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 12/07/2024.
//

import CoreData
import SwiftUI

struct JourneyRowView: View {
    @State var journey: Journey

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                if let startDate = journey.startDate {
                    Text(startDate.formattedDate())
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.leading)
                } else {
                    Text("N/A")
                        .font(.custom("Futura-Medium", size: 12.0, relativeTo: .subheadline))
                }
            }
            .frame(alignment: .leading)
            
            Divider()
            
            VStack(alignment: .leading) {
                if let departureStop = journey.departureStop {
                    Text(departureStop.stopinfo?.label ?? "N/A")
                        .font(.custom("Futura-Medium", size: 15.0, relativeTo: .title3))
                        .multilineTextAlignment(.leading)
                    
                    if let departureTimeUTC = departureStop.departureTimeUTC {
                        Text(departureTimeUTC.formattedTime())
                            .font(.caption2)
                            .fontWeight(.bold)
                    }
                } else {
                    Text("N/A")
                        .font(.custom("Futura-Medium", size: 15.0, relativeTo: .title3))
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(.leading, 8.0)
            
            Spacer()
            
            VStack(alignment: .center) {
                Image(systemName: "train.side.front.car")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20.0)
                    .foregroundColor(.blue)
                    .padding(.all, 3)
                
                HStack {
                    Spacer()
                    
                    Text(journey.company ?? "Unknown")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                    
                    VStack{Divider().frame(maxWidth: 50)}
                    
                    Text(journey.durationString())
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                    
                    Spacer()
                }
                .padding(.top, 3)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                if let arrivalStop = journey.arrivalStop {
                    Text(arrivalStop.stopinfo?.label ?? "N/A")
                        .font(.custom("Futura-Medium", size: 15.0, relativeTo: .title3))
                        .multilineTextAlignment(.trailing)
                    
                    if let arrivalTimeUTC = arrivalStop.arrivalTimeUTC {
                        Text(arrivalTimeUTC.formattedTime())
                            .font(.caption2)
                            .fontWeight(.bold)
                    }
                } else {
                    Text("N/A")
                        .font(.custom("Futura-Medium", size: 15.0, relativeTo: .title3))
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8.0)
    }
}

extension Date {
    func formattedDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm\ndd MMMM"
        return dateFormatter.string(from: self)
    }

    func formattedTime() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter.string(from: self)
    }
}

extension Journey {
    var departureStop: Stop? {
        return (stops as? Set<Stop>)?.first { $0.status == "departure" }
    }
    
    var arrivalStop: Stop? {
        return (stops as? Set<Stop>)?.first { $0.status == "arrival" }
    }

    func durationString() -> String {
        guard let startDate = startDate, let endDate = endDate else {
            return "N/A"
        }
        let interval = endDate.timeIntervalSince(startDate)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return String(format: "%02dh%02d", hours, minutes)
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
