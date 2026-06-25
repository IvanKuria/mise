import SwiftUI

/// Settings window: set the public Letterboxd username and an optional TMDB key,
/// toggle launch-at-login, and view app info + required attributions.
struct SettingsView: View {
    @Bindable var app: AppState

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "mise"
    }

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

            Section("General") {
                Toggle("Launch at login", isOn: Binding(
                    get: { app.launchAtLoginEnabled },
                    set: { app.setLaunchAtLogin($0) }
                ))
            }

            Section("About") {
                LabeledContent(appName) {
                    Text("Version \(appVersion)")
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("This product uses the TMDB API but is not endorsed or certified by TMDB.")
                    Text("Unofficial — not affiliated with Letterboxd.")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 480)
    }
}
