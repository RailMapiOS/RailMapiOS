//
//  DurationView.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 18/09/2024.
//


import SwiftUI

struct DurationView: View {
    let startDate: Date?
    let endDate: Date?
    
    var body: some View {
        HStack {
            VStack { Divider() }
            Text("Total \(calculateDurationString(from: startDate, to: endDate))")
            VStack { Divider() }
        }
        .padding(.horizontal)
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
