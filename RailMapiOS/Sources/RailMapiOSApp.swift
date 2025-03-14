import SwiftUI

@main
struct RailMapiOSApp: App {
    @StateObject private var dataController = DataController()
    @StateObject private var router = Router()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
                .environmentObject(dataController)
                .environmentObject(router)
                .preferredColorScheme(.light)
        }
    }
}
