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
        let (timeString, dateString) = dateFormatter(for: date)
        return HStack(alignment: .center) {
            StationLabel(station: stationLabel)
            Spacer()
            DateText(time: timeString, date: dateString)
        }
        .padding(.horizontal)
        .padding(.top)
    }
    
    func dateFormatter(for date: Date) -> (String, String) {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMMM"
        
        let timeString = timeFormatter.string(from: date)
        let dateString = dateFormatter.string(from: date)
        
        return (timeString, dateString)
    }
}
