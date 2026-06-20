import SwiftUI

@main
struct MiseApp: App {
    @State private var app = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(app)
                .frame(minWidth: 1040, minHeight: 720)
        }
        .windowToolbarStyle(.unified)
    }
}
