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

    init(
        title: String = "Add a ticket?",
        subtitle: String = "No journeys found",
        paragraph: String = "Try searching for another journey or add a new one."
    ) {
        self.title = title
        self.subtitle = subtitle
        self.paragraph = paragraph
    }

    var body: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: "train.side.front.car")
                .resizable()
                .foregroundStyle(.tertiary)
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 80)
                .padding(.bottom, 8)

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

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    EmptyListJourneyView()
}
