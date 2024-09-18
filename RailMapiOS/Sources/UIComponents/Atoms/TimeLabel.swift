//
//  TimeLabel.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 18/09/2024.
//


import SwiftUI

struct TimeLabel: View {
    let time: String
    let label: String
    
    var body: some View {
        VStack {
            Text(time)
                .font(.title2)
            Text(label)
                .font(.subheadline)
        }
    }
}
