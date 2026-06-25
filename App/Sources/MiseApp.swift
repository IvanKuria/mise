import SwiftUI

@main
struct MiseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        MenuBarExtra("mise", systemImage: "film.fill") {
            MenuBarContent(app: delegate.appState)
        }
        Settings {
            SettingsView(app: delegate.appState)
        }
    }
}

/// The menu-bar dropdown: current profile, sync, settings, quit.
private struct MenuBarContent: View {
    let app: AppState

    var body: some View {
        if app.currentHandle.isEmpty {
            Text("No username set")
        } else {
            Text("Viewing @\(app.currentHandle)")
        }
        Button("Open mise") { NotificationCenter.default.post(name: .miseOpenNotch, object: nil) }
        Button("Sync now") { Task { await app.syncNow() } }
            .disabled(app.currentHandle.isEmpty || app.isSyncing)
        Divider()
        Toggle("Launch at Login", isOn: Binding(
            get: { app.launchAtLoginEnabled },
            set: { app.setLaunchAtLogin($0) }
        ))
        SettingsLink { Text("Settings…") }
        Divider()
        Button("Quit mise") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }
}
