//
//  JourneyTimes.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 18/09/2024.
//


import SwiftUI

struct JourneyTimes: View {
    let departureTime: String
    let departureLabel: String
    let arrivalTime: String
    let arrivalLabel: String
    
    var body: some View {
        HStack {
            TimeLabel(time: departureTime, label: departureLabel)
            Spacer()
            TrainIcon()
            Spacer()
            TimeLabel(time: arrivalTime, label: arrivalLabel)
        }
    }
}
