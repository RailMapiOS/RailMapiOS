//
//  TrainTravelSummaryCard.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 16/02/2025.
//

import SwiftUI

struct TrainTravelSummaryCard: View {
    let numberOfTrips: Int
    let totalDistance: Double
    let timeSpentOnTrains: String
    let numberOfStationsVisited: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill( LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.8),
                        Color(cgColor: CGColor(red: 0.39, green: 0.26, blue: 1.00, alpha: 1.00)),
                        Color.purple.opacity(0.9)
                    ]),
                    startPoint: .topTrailing,
                    endPoint: .bottom
                ))
                .shadow(radius: 5)

            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: "train.side.front.car")
                        .font(.title2)
                        .foregroundColor(.white)
                        .opacity(0.9)
                    Text("Train summary")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.white)
                        .opacity(0.8)
                }
                .padding(.bottom, 5)

                SummaryRow(title: "Trips", value: "\(numberOfTrips)")
                SummaryRow(title: "Kilometres", value: String(format: "%.0f km", totalDistance))
                SummaryRow(title: "Time on board", value: timeSpentOnTrains)
                SummaryRow(title: "Stations visited", value: "\(numberOfStationsVisited)")
            }
            .padding(20)
            .foregroundColor(.white)
        }
        .frame(width: 350, height: 250)
        .padding()
    }
}

struct SummaryRow: View {
    let title: LocalizedStringResource
    /// Runtime data — distance, count, formatted duration. Rendered verbatim.
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .opacity(0.8)
            Spacer()
            Text(verbatim: value)
                .font(.title3)
                .fontWeight(.bold)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        TrainTravelSummaryCard(numberOfTrips: 42, totalDistance: 1245.67, timeSpentOnTrains: "2j 4h 32m", numberOfStationsVisited: 68)
            .preferredColorScheme(.dark)
    }
}
