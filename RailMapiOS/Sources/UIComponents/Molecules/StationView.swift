//
//  StationView.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 18/09/2024.
//


import SwiftUI

struct StationView: View {
    let stationLabel: String
    let date: Date
    
    var body: some View {
        let timeString = dateFormatter(for: date)
        return HStack(alignment: .center) {
            StationLabel(station: stationLabel)
            Spacer()
            DateText(time: timeString)
        }
        .padding(.horizontal)
        .padding(.top)
    }
    
    func dateFormatter(for date: Date) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        let timeString = timeFormatter.string(from: date)
        
        return timeString
    }
}
