import SwiftUI
import MiseCore
import MiseUI
import AppCore
import LocalStore
import CompareFeature

/// Compare section: prompts for a friend's public handle, loads their history via
/// a throwaway in-memory pipeline, then shows the comparison.
struct CompareLoaderView: View {
    @Environment(\.miseTheme) private var theme
    let me: WatchHistory

    @State private var friendHandle = ""
    @State private var phase: Phase = .idle
    @State private var friend: WatchHistory?

    private enum Phase: Equatable {
        case idle, loading, failed(String)
    }

    var body: some View {
        if let friend {
            CompareView(me: me, other: friend)
        } else {
            form
        }
    }

    private var form: some View {
        VStack(spacing: theme.spacing(2)) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 44))
                .foregroundStyle(theme.accent)
            Text("Compare with a friend")
                .font(theme.font(.title))
                .foregroundStyle(theme.primaryText)
            Text("Enter another public Letterboxd handle to see where your tastes meet and clash.")
                .font(theme.font(.body))
                .foregroundStyle(theme.secondaryText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 380)

            HStack {
                TextField("letterboxd.com / handle", text: $friendHandle)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(load)
                Button("Compare", action: load)
                    .buttonStyle(.borderedProminent)
                    .disabled(friendHandle.trimmingCharacters(in: .whitespaces).isEmpty || phase == .loading)
            }
            .frame(maxWidth: 380)

            if phase == .loading {
                ProgressView().controlSize(.small)
            }
            if case .failed(let message) = phase {
                Text(message)
                    .font(theme.font(.caption))
                    .foregroundStyle(.red)
            }
        }
        .padding(theme.spacing(3))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
    }

    private func load() {
        let handle = friendHandle.trimmingCharacters(in: .whitespaces)
        guard !handle.isEmpty else { return }
        phase = .loading
        Task {
            guard let store = try? LibraryStore(inMemory: true) else {
                phase = .failed("Couldn't prepare a temporary store.")
                return
            }
            let loader = LibraryController(store: store)
            await loader.load(handle: handle, tmdbKey: nil)
            switch loader.phase {
            case .done:
                if let other = loader.history {
                    friend = other
                } else {
                    phase = .failed("No public data found for “\(handle)”.")
                }
            case .failed(let message):
                phase = .failed(message)
            default:
                phase = .failed("Couldn't load “\(handle)”.")
            }
        }
    }
}
