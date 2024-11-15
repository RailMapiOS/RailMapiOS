//
//  StationView.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 18/09/2024.
//

import Helpers
import SwiftUI

struct StationView: View {
    let stationLabel: String
    let date: Date
    let arrival: Bool
    
    var body: some View {
        return HStack(alignment: .center) {
            StationLabel(station: stationLabel)
            Spacer()
            DateText(time: date.formattedTime(),
                     timeRemaining: date.timeRemainingDescription(),
                     arrival: arrival)
        }
        .padding(.horizontal)
        .padding(.top)
    }
}
