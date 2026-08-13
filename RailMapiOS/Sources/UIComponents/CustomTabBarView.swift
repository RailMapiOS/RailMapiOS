//
//  CustomTabBarView.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 05/08/2025.
//


import SwiftUI

struct CustomTabBarView: View {
    @Binding var selectedTab: TabItem
    /// Safe area actually available under the bar, measured — it varies with
    /// orientation and with how iOS places the sheet.
    @State private var safeAreaBottom: CGFloat = 0

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
        // The bar used to contribute no bottom room at all: the gap under the
        // labels was entirely the ambient safe area — ~34pt of home indicator in
        // portrait. Anywhere that inset shrinks (landscape, and the wide iPhone
        // layouts where iOS 27 floats the sheet against an edge) the labels ended
        // up nearly on the sheet's edge. Top up to a floor instead of stacking on
        // top, so portrait is unchanged.
        .padding(.bottom, max(0, Self.minimumBottomInset - safeAreaBottom))
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.safeAreaInsets.bottom
        } action: { safeAreaBottom = $0 }
    }

    /// Clearance the labels always keep below them, safe area included.
    private static let minimumBottomInset: CGFloat = 20
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
