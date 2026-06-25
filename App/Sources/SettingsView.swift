import SwiftUI

/// Settings window: set the public Letterboxd username and an optional TMDB key.
struct SettingsView: View {
    @Bindable var app: AppState

    var body: some View {
        Form {
            Section("Letterboxd") {
                TextField("Public username", text: $app.currentHandle)
                    .textContentType(.username)
                Button("Load profile") {
                    Task { await app.switchTo(handle: app.currentHandle) }
                }
                .disabled(app.currentHandle.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            Section("Posters (optional)") {
                SecureField("TMDB API key", text: $app.tmdbKey)
                Text("Enables poster art. Without it, films show as title + year.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !app.recentHandles.isEmpty {
                Section("Recent profiles") {
                    ForEach(app.recentHandles, id: \.self) { handle in
                        Button("@\(handle)") { Task { await app.switchTo(handle: handle) } }
                    }
                }
            }

            Section {
                Button("Sync now") { Task { await app.syncNow() } }
                    .disabled(app.currentHandle.isEmpty || app.isSyncing)
            }
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 360)
    }
}
