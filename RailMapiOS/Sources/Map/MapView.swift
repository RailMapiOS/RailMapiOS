import SwiftUI
import MapKit

struct MapView: View {
    @Binding var sheetSize: PresentationDetent
    @ObservedObject var mapSettings: MapSettings
    @State private var bottomSheetHeight: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            Map(position: $mapSettings.cameraPosition) {
                mapContent
            }
            .mapStyle(.standard)
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear
                    .frame(height: bottomSheetHeight)
            }
            .onAppear {
                updateBottomSheetHeight(screenHeight: proxy.size.height)
                if mapSettings.selectedRoute == nil {
                    mapSettings.updateCameraToShowAllRoutes()
                }
            }
            .onChange(of: sheetSize) { _, _ in
                updateBottomSheetHeight(screenHeight: proxy.size.height)
            }
        }
    }

    private var mapContent: some MapContent {
        ForEach(mapSettings.trainRoutes) { route in
            let isSelected = mapSettings.selectedRoute?.id == route.id
            let hasSelection = mapSettings.selectedRoute != nil

            MapPolyline(coordinates: route.coordinates)
                .stroke(
                    route.routeColor.opacity(hasSelection && !isSelected ? 0.3 : 1.0),
                    lineWidth: isSelected ? 5 : 3
                )
                .mapOverlayLevel(level: isSelected ? .aboveRoads : .aboveLabels)

            if let firstCoord = route.coordinates.first {
                Annotation("", coordinate: firstCoord) {
                    Circle()
                        .fill(route.routeColor)
                        .frame(width: isSelected ? 10 : 7, height: isSelected ? 10 : 7)
                        .opacity(hasSelection && !isSelected ? 0.3 : 1.0)
                }
            }

            ForEach(1..<max(1, route.coordinates.count - 1), id: \.self) { index in
                Annotation("", coordinate: route.coordinates[index]) {
                    Circle()
                        .fill(route.routeColor.opacity(0.7))
                        .frame(width: 5, height: 5)
                        .opacity(hasSelection && !isSelected ? 0.3 : 1.0)
                }
            }

            if let lastCoord = route.coordinates.last, route.coordinates.count > 1 {
                Annotation("", coordinate: lastCoord) {
                    Circle()
                        .fill(route.routeColor)
                        .frame(width: isSelected ? 10 : 7, height: isSelected ? 10 : 7)
                        .opacity(hasSelection && !isSelected ? 0.3 : 1.0)
                }
            }
        }
    }

    private func updateBottomSheetHeight(screenHeight: CGFloat) {
        switch sheetSize {
        case .medium:
            bottomSheetHeight = screenHeight * 0.5
        case .large:
            bottomSheetHeight = screenHeight * 0.8
        default:
            bottomSheetHeight = screenHeight * 0.3
        }
    }
}
