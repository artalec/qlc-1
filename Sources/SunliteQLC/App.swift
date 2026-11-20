import SwiftUI

@main
struct SunliteQLCApp: App {
    @StateObject private var client = QLCPlusClient()
    @StateObject private var document = LightingDocument()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(client)
                .environmentObject(document)
                .frame(minWidth: 1150, minHeight: 720)
        }
    }
}
