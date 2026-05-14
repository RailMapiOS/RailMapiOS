//
//  DurationView.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 18/09/2024.
//

import Helpers
import SwiftUI

//TODO: Calculer la distance et l'afficher
struct DurationView: View {
    let startDate: Date?
    let endDate: Date?
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "clock")
                .foregroundStyle(.gray)
            Text(verbatim: calculateDurationString(from: startDate, to: endDate))
                .font(.subheadline)
                .foregroundStyle(.gray)
            VStack { Divider() }
        }
        .padding(.horizontal)
    }

    func calculateDurationString(from startDate: Date?, to endDate: Date?) -> String {
        guard let startDate = startDate, let endDate = endDate else {
            return String(localized: "Duration unavailable", comment: "Fallback shown when journey start or end is missing.")
        }
        return startDate.duration(to: endDate)
    }
}

#Preview {
    DurationView(startDate: Date.now, endDate: Date.distantFuture)
}
