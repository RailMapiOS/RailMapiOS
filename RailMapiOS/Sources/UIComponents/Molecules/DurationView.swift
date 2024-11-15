//
//  DurationView.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 18/09/2024.
//

import Helpers
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
        
        return startDate.duration(to: endDate)
    }
}
