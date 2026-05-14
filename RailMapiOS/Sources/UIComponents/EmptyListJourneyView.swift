//
//  EmptyListJourneyView.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 19/01/2025.
//

import SwiftUI

struct EmptyListJourneyView: View {
    /// Strings flow through `LocalizedStringResource` so callers can override
    /// per-context (different empty states for the journeys list vs search).
    private var title: LocalizedStringResource
    private var subtitle: LocalizedStringResource
    private var paragraph: LocalizedStringResource
    var compact: Bool = false

    init(
        title: LocalizedStringResource = LocalizedStringResource("Add a journey?", comment: "Empty-state title for the journeys list."),
        subtitle: LocalizedStringResource = LocalizedStringResource("No journeys yet", comment: "Empty-state subtitle for the journeys list."),
        paragraph: LocalizedStringResource = LocalizedStringResource("Search for a journey by its train number.", comment: "Empty-state instruction text."),
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
