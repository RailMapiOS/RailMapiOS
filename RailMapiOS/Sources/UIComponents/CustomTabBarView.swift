//
//  CustomTabBarView.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 05/08/2025.
//


import SwiftUI

struct CustomTabBarView: View {
    @Binding var selectedTab: TabItem

    var body: some View {
        VStack {
            Divider()

            HStack {
                ForEach(TabItem.allCases, id: \.self) { tab in
                    TabBarButton(tab: tab, isSelected: selectedTab == tab) {
                        selectedTab = tab
                    }
                }
            }
            .padding(.top, 10)
        }
    }
}

struct TabBarButton: View {
    let tab: TabItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 22))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .frame(height: 24)

                Text(tab.title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 49)
            .contentShape(Rectangle())
        }
        .buttonStyle(TabBarButtonStyle())
    }
}

struct TabBarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

enum TabItem: CaseIterable {
    case journeys, friends, profile, search

    var title: LocalizedStringResource {
        switch self {
        case .journeys: return LocalizedStringResource("My Journeys", comment: "Tab bar title for the saved journeys list.")
        case .friends:  return LocalizedStringResource("Friends", comment: "Tab bar title for the (future) friends feed.")
        case .profile:  return LocalizedStringResource("Profile", comment: "Tab bar title for the user's profile / account.")
        case .search:   return LocalizedStringResource("Search", comment: "Tab bar title for the train search tab.")
        }
    }

    var icon: String {
        switch self {
        case .journeys: return "lightrail"
        case .friends: return "person.3"
        case .profile: return "person"
        case .search: return "magnifyingglass"
        }
    }

    var selectedIcon: String {
        switch self {
        case .journeys: return "lightrail.fill"
        case .friends: return "person.3.fill"
        case .profile: return "person.fill"
        case .search: return "magnifyingglass"
        }
    }
}
