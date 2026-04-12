import ComposableArchitecture
import SwiftUI

@main
struct RailMapiOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // TCA store is the single source of truth
    static let store = Store(initialState: AppFeature.State()) { AppFeature() }

    // DataController still needed for SwiftData ModelContainer + legacy views during migration
    @StateObject private var dataController = DataController()

    var body: some Scene {
        WindowGroup {
            AppView(store: Self.store)
                .modelContainer(dataController.modelContainer)
                .environmentObject(dataController) // kept for legacy views not yet migrated
                .onAppear {
                    DataControllerClient.shared = dataController
                    // DataController shared ref for TCA dependencies
                    // Old MapSettings is no longer used — MapFeature handles routes now
                }
        }
    }
}
