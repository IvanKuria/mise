import FilmEnrichment
import Foundation
import LetterboxdScrape
import LocalStore
import MiseCore
import TMDBKit

/// The runtime spine the SwiftUI app drives: takes a Letterboxd handle (and an
/// optional TMDB key), builds the scrape → enrich → sync pipeline, runs it, and
/// publishes observable state for the UI.
///
/// Dependencies are injected as closures so tests can substitute a mock fetcher,
/// an in-memory store, and a mock metadata provider with no network. The
/// convenience initializer wires the real `ScrapingFetcher` + in-app
/// `LibraryStore`.
@MainActor
@Observable
public final class LibraryController {
    /// Where the pipeline currently is. Carries messages for the failure case.
    public enum Phase: Equatable, Sendable {
        case idle
        case syncing
        case enriching
        case done
        case failed(String)
    }

    // MARK: - Published state

    public private(set) var phase: Phase = .idle
    public private(set) var progress: Double = 0
    public private(set) var history: WatchHistory?
    public private(set) var errorMessage: String?

    // MARK: - Injected collaborators

    /// Builds the base (un-enriched) fetcher. Real impl: `ScrapingFetcher`.
    /// `@MainActor` so it can construct the WKWebView-backed grid fetcher.
    private let makeFetcher: @MainActor @Sendable () -> any LetterboxdFetching
    /// Builds a `FilmEnricher` for a non-empty TMDB key, or `nil` to skip
    /// enrichment. Real impl: a `FilmEnricher` over a `TMDBClient`.
    private let makeEnricher: @Sendable (_ tmdbKey: String) -> FilmEnricher?
    /// The persistence store. Real impl: `LibraryStore`.
    private let store: any HistoryStoring

    /// Designated initializer for tests and custom wiring.
    ///
    /// - Parameters:
    ///   - store: The history store (e.g. an in-memory mock).
    ///   - makeFetcher: Produces the base fetcher to wrap.
    ///   - makeEnricher: Produces an enricher for a TMDB key, or `nil` to skip.
    public init(
        store: any HistoryStoring,
        makeFetcher: @escaping @MainActor @Sendable () -> any LetterboxdFetching,
        makeEnricher: @escaping @Sendable (_ tmdbKey: String) -> FilmEnricher?
    ) {
        self.store = store
        self.makeFetcher = makeFetcher
        self.makeEnricher = makeEnricher
    }

    /// Convenience initializer wiring the real `ScrapingFetcher` and an enricher
    /// backed by a live `TMDBClient`.
    ///
    /// - Parameter store: The persistence store, typically a `LibraryStore` over
    ///   the app's shared `ModelContainer`.
    public convenience init(store: any HistoryStoring) {
        self.init(
            store: store,
            makeFetcher: { @MainActor in
                // The RSS feed (primary) + profile/diary are reliably fetched over
                // URLSession. The /films/ grid is populated by an authenticated
                // React/GraphQL call, so it isn't publicly scrapable even via a
                // headless browser — RSS is the public source of truth.
                //
                // Cap pagination low: the notch is driven by the diary (RSS, one
                // request); watchlist/lists are fetched by the pipeline but not
                // shown, so walking dozens of their pages just stalls the sync.
                ScrapingFetcher(maxPages: 4)
            },
            makeEnricher: { key in
                FilmEnricher(provider: TMDBClient(apiKey: key))
            }
        )
    }

    // MARK: - Pipeline

    /// Builds and runs the pipeline for `handle`, publishing progress and the
    /// merged history. Errors are caught into `.failed` / `errorMessage`.
    ///
    /// - Parameters:
    ///   - handle: The Letterboxd handle to sync.
    ///   - tmdbKey: A TMDB key enabling enrichment; empty/`nil` runs without it.
    public func load(handle: String, tmdbKey: String?) async {
        errorMessage = nil
        progress = 0
        phase = .syncing

        let enricher: FilmEnricher?
        if let tmdbKey, !tmdbKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            enricher = makeEnricher(tmdbKey)
        } else {
            enricher = nil
        }

        let fetcher = EnrichingFetcher(base: makeFetcher(), enricher: enricher)
        let engine = SyncEngine(fetcher: fetcher, store: store)

        let hasEnricher = enricher != nil
        // The progress callback is invoked off the main actor by SyncEngine; hop
        // back to the main actor to mutate published state.
        let onProgress: @Sendable (SyncProgress) -> Void = { [weak self] stage in
            Task { @MainActor [weak self] in
                self?.apply(stage, hasEnricher: hasEnricher)
            }
        }

        do {
            let merged = try await engine.sync(username: handle, onProgress: onProgress)
            history = merged
            progress = 1
            phase = .done
        } catch {
            let message = error.localizedDescription
            errorMessage = message
            phase = .failed(message)
        }
    }

    /// Loads a ready-made history directly (used by the built-in demo, and tests).
    public func loadSample(_ history: WatchHistory) {
        self.history = history
        self.progress = 1
        self.phase = .done
    }

    /// Publishes any cached history for `handle` from the store WITHOUT hitting
    /// the network, so the UI can show data instantly on launch / profile switch.
    /// A subsequent `load(handle:tmdbKey:)` refreshes it from Letterboxd.
    /// No-op (leaves current state) if nothing is cached for the handle.
    @discardableResult
    public func restoreCached(handle: String) async -> Bool {
        let trimmed = handle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        if let cached = try? await store.loadHistory(username: trimmed) {
            history = cached
            progress = 1
            phase = .done
            return true
        }
        return false
    }

    // MARK: - Progress mapping

    /// Maps a coarse `SyncProgress` stage onto `phase` and a 0...1 fraction.
    private func apply(_ stage: SyncProgress, hasEnricher: Bool) {
        switch stage {
        case .resolvingMember:
            phase = .syncing
            progress = 0.1
        case .fetchingStatistics:
            phase = .syncing
            progress = 0.25
        case .fetchingDiary:
            // Diary/watchlist/list fetches are where enrichment happens.
            phase = hasEnricher ? .enriching : .syncing
            progress = 0.45
        case .fetchingWatchlist:
            phase = hasEnricher ? .enriching : .syncing
            progress = 0.6
        case .fetchingLists:
            phase = hasEnricher ? .enriching : .syncing
            progress = 0.75
        case .merging:
            phase = .syncing
            progress = 0.85
        case .saving:
            phase = .syncing
            progress = 0.95
        case .finished:
            progress = 1
        }
    }
}
