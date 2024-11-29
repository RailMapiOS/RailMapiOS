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
    
    var body: some View {
        VStack(alignment: .trailing) {
            Text(time)
                .fontWeight(.semibold)
                .font(.largeTitle)
            Text("\(arrival ? "Arrivé" : "Départ") dans \(timeRemaining)")
                .fontWeight(.semibold)
                .foregroundStyle(.gray)
                .font(.caption2)
        }
    }
}
