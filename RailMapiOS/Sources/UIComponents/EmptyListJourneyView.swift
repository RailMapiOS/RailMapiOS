//
//  EmptyListJourneyView.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 19/01/2025.
//

import SwiftUI

struct EmptyListJourneyView: View {
    private var title: String
    private var subtitle: String
    private var paragraph: String
    var compact: Bool = false

    init(
        title: String = "Ajouter un trajet ?",
        subtitle: String = "Aucun trajet trouvé",
        paragraph: String = "Recherchez un trajet par numéro de train.",
        compact: Bool = false
    ) {
        self.title = title
        self.subtitle = subtitle
        self.paragraph = paragraph
        self.compact = compact
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if !compact {
                    Image(systemName: "train.side.front.car")
                        .resizable()
                        .foregroundStyle(.tertiary)
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 80)
                        .padding(.bottom, 8)
                }

                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(paragraph)
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 16)
        }
    }
}

#Preview {
    EmptyListJourneyView()
}
