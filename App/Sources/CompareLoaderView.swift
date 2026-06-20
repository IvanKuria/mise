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
        VStack(alignment: .leading, spacing: theme.spacing(2)) {
            Text("TASTE MATCH")
                .font(theme.font(.caption))
                .tracking(2.5)
                .foregroundStyle(theme.accent)
            Text("Compare with a friend")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(theme.textPrimary)
            Text("Enter another public Letterboxd handle to see where your tastes meet and clash.")
                .font(theme.font(.body))
                .foregroundStyle(theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: theme.spacing(1)) {
                TextField("letterboxd.com/handle", text: $friendHandle)
                    .textFieldStyle(.plain)
                    .font(theme.font(.body))
                    .foregroundStyle(theme.textPrimary)
                    .padding(.horizontal, theme.spacing(1.5))
                    .padding(.vertical, theme.spacing(1.25))
                    .miseField(theme)
                    .onSubmit(load)
                Button(action: load) {
                    Text("Compare")
                        .font(theme.font(.headline))
                        .foregroundStyle(theme.onSelection)
                        .padding(.horizontal, theme.spacing(2))
                        .padding(.vertical, theme.spacing(1.25))
                        .background(
                            RoundedRectangle(cornerRadius: theme.smallCornerRadius, style: .continuous)
                                .fill(theme.accent)
                        )
                }
                .buttonStyle(.plain)
                .disabled(friendHandle.trimmingCharacters(in: .whitespaces).isEmpty || phase == .loading)
            }

            if phase == .loading {
                ProgressView().controlSize(.small)
            }
            if case .failed(let message) = phase {
                Text(message)
                    .font(theme.font(.caption))
                    .foregroundStyle(theme.secondaryAccent)
            }
        }
        .frame(maxWidth: 420, alignment: .leading)
        .padding(theme.spacing(4))
        .miseCard(theme)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.clear)
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
