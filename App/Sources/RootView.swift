import SwiftUI
import MiseUI
import OnboardingFeature

/// Gates between onboarding (no history yet) and the main shell, and applies the
/// active theme to the whole app so Theme Studio edits re-skin everything live.
struct RootView: View {
    @Environment(AppState.self) private var app
    @State private var onboarding = OnboardingModel()

    var body: some View {
        Group {
            if let history = app.library.history {
                MainShell(history: history)
            } else {
                OnboardingView(model: onboarding, onSubmit: startLoad)
            }
        }
        .miseTheme(app.themeModel.theme)
    }

    private func startLoad(handle: String, tmdbKey: String?) {
        Task {
            onboarding.status = .syncing(progress: 0, message: "Reading your films…")
            await app.library.load(handle: handle, tmdbKey: tmdbKey)
            switch app.library.phase {
            case .failed(let message):
                onboarding.status = .failed(message)
            default:
                onboarding.status = .done
            }
        }
    }
}
