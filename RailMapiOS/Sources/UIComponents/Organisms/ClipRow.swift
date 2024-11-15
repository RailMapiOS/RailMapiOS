//
//  ClipRown.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 15/11/2024.
//

import SwiftUI

struct ClippedRow: View {
    var header: String?
    var title: String?
    var bodyTexts: [String?]
    var icon: String?
    
    var body: some View {
        VStack(spacing: 8) {
            if let header = header {
                HStack {
                    Text(header)
                        .fontWeight(.semibold)
                        .font(.headline)
                }
                Divider()
            }
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 45)
                        .padding(.horizontal, 10)
                }
                VStack(alignment: .leading) {
                    if let title = title {
                        Text(title)
                            .font(.body)
                            .fontWeight(.semibold)
                    }
                    ForEach(bodyTexts.compactMap { $0 }, id: \.self) { text in
                        Text(text)
                            .font(.body)
                            .foregroundStyle(.gray)
                    }
                }
                Spacer()
            }
        }
        .padding()
        .background(            RoundedRectangle(cornerRadius: 20)
            .fill(.white)
        )
        .background(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.gray, lineWidth: 1.0)
                .opacity(0.5)
                .shadow(color: .gray, radius: 2, x: 2, y: 2)
        )
        .padding(.horizontal)
    }
}

#Preview {
    ClippedRow(
        title: "Prévision à l'arrivée",
        bodyTexts: ["11°C et ensoleillé"],
        icon: "cloud.sun.fill"
    )
}
