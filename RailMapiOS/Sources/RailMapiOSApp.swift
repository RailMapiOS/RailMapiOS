import SwiftUI

@main
struct RailMapiOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var dataController = DataController()
    @StateObject private var router = Router()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(dataController.modelContainer)
                .environmentObject(dataController)
                .environmentObject(router)
                .preferredColorScheme(.light)
        }
    }
}
