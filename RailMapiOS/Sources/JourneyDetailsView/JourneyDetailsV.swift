//
//  JourneyDetailsV.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 19/07/2024.
//

import SwiftUI
import SwiftData

struct JourneyDetailsV: View {
    @EnvironmentObject var dataController: DataController
    let journey: Journey
    
    var departureLabel: String {
        guard let stops = journey.stops,
              let departureStop = stops.first(where: { $0.status == "departure" }) else {
            return "N/A"
        }
        return departureStop.stopinfo?.label ?? "N/A"
    }
    
    var arrivalLabel: String {
        guard let stops = journey.stops,
              let arrivalStop = stops.first(where: { $0.status == "arrival" }) else {
            return "N/A"
        }
        return arrivalStop.stopinfo?.label ?? "N/A"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header du trajet
            JourneyHeaderView(
                company: journey.company,
                headsign: journey.headsign,
                departureCity: departureLabel,
                arrivalCity: arrivalLabel,
                departureDate: journey.startDate,
                size: CGSize(width: 60, height: 60)
            )
            
            Divider()
            
            ScrollView(showsIndicators: true) {
                VStack(spacing: 16) {
                    // Statut de départ
                    if let startDate = journey.startDate {
                        DepartureStatusView(
                            status: .intime,
                            time: startDate,
                            station: "Gare de Lyon",
                            hall: "3",
                            platform: nil
                        )
                    }
                    
                    // Informations de trajet
                    VStack {
                        StationView(
                            stationLabel: departureLabel,
                            date: journey.startDate ?? Date(),
                            arrival: false
                        )
                        
                        DurationView(
                            startDate: journey.startDate,
                            endDate: journey.endDate
                        )
                        
                        StationView(
                            stationLabel: arrivalLabel,
                            date: journey.endDate ?? Date(),
                            arrival: true
                        )
                    }
                    .padding(.vertical)
                    
                    // Informations de réservation
                    HStack {
                        ClippedRow(
                            title: "Booking Code",
                            bodyTexts: ["Tap to Edit"],
                            icon: "ticket.fill",
                            displayMode: .small
                        )
                        
                        ClippedRow(
                            title: "Seat",
                            bodyTexts: ["Tap to Edit"],
                            icon: "carseat.right.fill",
                            displayMode: .small
                        )
                    }
                    .padding()
                    
                    // Section "Good to know"
                    LazyVStack(alignment: .leading) {
                        Text("Good to know")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        ClippedRow(
                            title: "Prévision à l'arrivée",
                            bodyTexts: ["14°C et ensoleillée"],
                            icon: "cloud.sun.fill"
                        )
                        
                        ClippedRow(
                            title: "My history on This Route",
                            bodyTexts: [
                                "14°C et ensoleillée",
                                "13°C et ensoleillée",
                                "12°C et ensoleillée"
                            ],
                            displayMode: .large
                        )
                        
                        ClippedRow(
                            title: "My history on This Route",
                            bodyTexts: [
                                "14°C et ensoleillée",
                                "13°C et ensoleillée",
                                "12°C et ensoleillée"
                            ],
                            displayMode: .large
                        )
                        
                        ClippedRow(
                            title: "My history on This Route",
                            bodyTexts: [
                                "14°C et ensoleillée",
                                "13°C et ensoleillée",
                                "12°C et ensoleillée"
                            ],
                            displayMode: .large
                        )
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .ignoresSafeArea()
            .padding(.top, -15)
            .padding(.vertical)
            
            Spacer()
        }
        .ignoresSafeArea(.container, edges: .vertical)
    }
}

// Preview adapté pour SwiftData
#Preview {
    // Créer un trajet fictif pour la preview
    let journey = Journey()
    journey.id = UUID()
    journey.headsign = "Paris -> Lyon"
    journey.company = "SNCF"
    journey.startDate = Date()
    journey.endDate = Date().addingTimeInterval(3600) // 1 heure plus tard
    journey.archived = false
    
    // Créer des arrêts fictifs
    let departureStopInfo = StopInfos()
    departureStopInfo.id = UUID().uuidString
    departureStopInfo.label = "Gare de Lyon"
    departureStopInfo.latitude = 48.8444
    departureStopInfo.longitude = 2.3732
    
    let departureStop = Stop()
    departureStop.arrivalTimeUTC = journey.startDate
    departureStop.departureTimeUTC = journey.startDate
    departureStop.status = "departure"
    departureStop.stopinfo = departureStopInfo
    departureStopInfo.stop = departureStop
    
    let arrivalStopInfo = StopInfos()
    arrivalStopInfo.id = UUID().uuidString
    arrivalStopInfo.label = "Gare de Lyon Part-Dieu"
    arrivalStopInfo.latitude = 45.7603
    arrivalStopInfo.longitude = 4.8590
    
    let arrivalStop = Stop()
    arrivalStop.arrivalTimeUTC = journey.endDate
    arrivalStop.departureTimeUTC = journey.endDate
    arrivalStop.status = "arrival"
    arrivalStop.stopinfo = arrivalStopInfo
    arrivalStopInfo.stop = arrivalStop
    
    journey.stops = [departureStop, arrivalStop]
    
    return JourneyDetailsV(journey: journey)
        .environmentObject(DataController())
}
