import SwiftUI

@main
struct ClipKeepApp: App {
    @StateObject private var store = ClipStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
