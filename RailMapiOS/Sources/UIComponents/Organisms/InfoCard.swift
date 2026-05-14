//
//  InfoCard.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 15/11/2024.
//

import SwiftUI

struct InfoCard: View {
    var header: String?
    var title: String?
    var bodyTexts: [String?]? = nil
    var icon: String?
    var displayMode: DisplayMode = .medium
    var content: (() -> AnyView)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if header != nil {
                headerView
            }
            contentView(for: displayMode)
            
            if let content = content {
                content()
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)

    }
    
    // MARK: - Header View
    @ViewBuilder
    private var headerView: some View {
        Text(header!)
            .fontWeight(.semibold)
            .font(.headline)
        Divider()
    }
    
    // MARK: - Content View
    @ViewBuilder
    private func contentView(for mode: DisplayMode) -> some View {
        switch mode {
        case .small:
            smallContentView
        case .medium:
            mediumContentView
        case .large:
            mediumContentView
        }
    }
    
    // MARK: - Small Content View
    private var smallContentView: some View {
        HStack {
            VStack(alignment: .leading) {
                if icon != nil {
                    iconView(for: .small)
                }
                
                if let title = title {
                    Text(title)
                        .font(.body)
                        .fontWeight(.semibold)
                }
                
                if let bodyTexts = bodyTexts {
                    ForEach(bodyTexts.compactMap { $0 }, id: \.self) { text in
                        Text(text)
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }
                }
            }
            Spacer()
        }
    }
    
    // MARK: - Medium Content View
    private var mediumContentView: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            HStack {
                if icon != nil {
                    iconView(for: .medium)
                }
                VStack(alignment: .leading) {
                    if let title = title {
                        Text(title)
                            .font(.body)
                            .fontWeight(.semibold)
                    }
                    
                    if let bodyTexts = bodyTexts {
                        ForEach(bodyTexts.compactMap { $0 }, id: \.self) { text in
                            Text(text)
                                .font(.body)
                                .foregroundStyle(.gray)
                        }
                    }
                }
                Spacer()
            }
        }
    }
    
    // MARK: - Icon View

    
    private func iconView(for mode: DisplayMode) -> some View {
        let size: CGFloat
        let padding: CGFloat
        
        switch mode {
        case .small:
            size = 30
            padding = 0
        case .medium:
            size = 45
            padding = 10
        case .large:
            size = 60
            padding = 12
        }
        
        if let icon = icon {
            return AnyView(Image(systemName: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .padding(.horizontal, padding))
        } else {
            return AnyView(EmptyView())
        }
    }

}



// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        HStack(spacing: 16) {
            InfoCard(
                title: "Booking reference",
                bodyTexts: ["Not provided"],
                icon: "ticket.fill",
                displayMode: .small
            )

            InfoCard(
                title: "Seat",
                bodyTexts: ["Not provided"],
                icon: "carseat.right.fill",
                displayMode: .small
            )
        }
        InfoCard(
            header: "Medium Mode",
            title: "Weather at arrival",
            bodyTexts: ["11°C, sunny"],
            icon: "cloud.sun.fill",
            displayMode: .medium
        )
        
        InfoCard(
            content: {
                AnyView(
                    HStack {
                        Image(systemName: "clock")
                        Image(systemName: "clock")
                        Image(systemName: "clock")
                    }
                )
            }
        )
    }
}

// MARK: - DisplayMode Enum
enum DisplayMode {
    case small, medium, large
}
