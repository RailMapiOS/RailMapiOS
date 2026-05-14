//
//  DateText.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 18/09/2024.
//


import SwiftUI

struct DateText: View {
    let time: String
    let timeRemaining: String
    let arrival: Bool
    
    private var timeRemainingText: String
    
    public init(time: String, timeRemaining: String, arrival: Bool) {
        self.time = time
        self.timeRemaining = timeRemaining
        self.arrival = arrival

        // The "already departed" string is produced by the Helpers package
        // through the app's String Catalog; we compare against the current
        // localized form to detect that branch.
        let alreadyDeparted = String(localized: "Already departed", comment: "Shown when a journey's start date is in the past.")
        self.timeRemainingText = {
            if timeRemaining == alreadyDeparted {
                return alreadyDeparted
            }
            // Two distinct verb forms to translate (arrives vs departs in X).
            return arrival
                ? String(localized: "Arrives in \(timeRemaining)", comment: "Time-to-arrival label, e.g. 'Arrives in 12 min'.")
                : String(localized: "Departs in \(timeRemaining)", comment: "Time-to-departure label, e.g. 'Departs in 12 min'.")
        }()
    }

    var body: some View {
        VStack(alignment: .trailing) {
            Text(time)
                .fontWeight(.semibold)
                .font(.largeTitle)
            Text(timeRemainingText)
                .fontWeight(.semibold)
                .foregroundStyle(.gray)
                .font(.caption2)
        }
    }
}
