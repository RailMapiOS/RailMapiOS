//
//  DepartureStatusView.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 29/11/2024.
//

import SwiftUI
import Helpers

struct DepartureStatusView: View {
    
    var status: DepartureStatus = .unknown
    var time: Date
    var station: String
    var hall: String?
    var platform: String?
    
    var body: some View {
        VStack(spacing: 0) {
            switch status {
            case .cancelled:
                Text("Train annulé")
            case .delayed:
                Text("Train retardé, retard estimé à XX minutes")
            default:
                VStack(alignment: .leading) {
                    HStack {
                        Text("Départ dans")
                            .fontWeight(.semibold)
                        Text(time.timeRemainingDescription())
                            .fontWeight(.semibold)
                            .foregroundStyle(.green.mix(with: .black, by: 0.05))
                        
                        if let platfom = self.platform {
                            Text("au Quai")
                                .fontWeight(.semibold)
                            Text(platfom)
                                .fontWeight(.semibold)
                                .foregroundStyle(.green.mix(with: .black, by: 0.05))
                        }else if let hall = self.hall {
                            Text("au Hall")
                                .fontWeight(.semibold)
                            Text(hall)
                                .fontWeight(.semibold)
                                .foregroundStyle(.green.mix(with: .black, by: 0.05))
                        }
                        
                        Spacer()
                    }
                }
                .padding()
                .background(.green.opacity(0.05))
            }
            Divider()
        }
    }
    
    enum DepartureStatus {
        case intime, cancelled, delayed, unknown
    }
}

#Preview {
    VStack {
        DepartureStatusView(time: Date.distantFuture, station: "Gare de Perpignan")
        DepartureStatusView(time: Date.distantFuture, station: "Gare de Perpignan", hall: "3")
        DepartureStatusView(time: Date.distantFuture, station: "Gare de Perpignan", hall: "3", platform: "A")
        }
}
