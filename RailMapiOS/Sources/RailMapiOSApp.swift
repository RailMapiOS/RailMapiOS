import ComposableArchitecture
import SwiftUI

@main
struct RailMapiOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    /// TCA store: single source of truth.
    static let store = Store(initialState: AppFeature.State()) { AppFeature() }

    /// SwiftData service shared across the app.
    @State private var dataService: DataService = {
        do {
            let service = try DataService()
            DataControllerClient.shared = service
            return service
        } catch {
            fatalError("Failed to initialize SwiftData: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppView(store: Self.store)
                .modelContainer(dataService.modelContainer)
        }
    }
}
