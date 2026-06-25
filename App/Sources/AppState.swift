import Foundation
import Observation
import AppCore
import LocalStore
import MiseCore

/// App-wide state for the notch app: the scraping pipeline controller plus the
/// persisted username/recents/TMDB-key settings. `@Observable` so the notch UI
/// re-renders as history loads.
@MainActor
@Observable
final class AppState {
    let library: LibraryController

    /// The currently-viewed public Letterboxd username (persisted).
    var currentHandle: String {
        didSet { defaults.set(currentHandle, forKey: Keys.currentHandle) }
    }
    /// Previously-viewed usernames, most-recent first (persisted) — powers the
    /// click-the-name profile switcher.
    var recentHandles: [String] {
        didSet { defaults.set(recentHandles, forKey: Keys.recentHandles) }
    }
    /// Optional TMDB API key enabling poster art (persisted).
    var tmdbKey: String {
        didSet { defaults.set(tmdbKey, forKey: Keys.tmdbKey) }
    }

    var history: WatchHistory? { library.history }
    var phase: LibraryController.Phase { library.phase }
    var isSyncing: Bool {
        switch library.phase { case .syncing, .enriching: return true; default: return false }
    }

    private let defaults = UserDefaults.standard
    private enum Keys {
        static let currentHandle = "currentHandle"
        static let recentHandles = "recentHandles"
        static let tmdbKey = "tmdbKey"
    }

    init() {
        let store: any HistoryStoring = AppState.makeStore()
        self.library = LibraryController(store: store)
        self.currentHandle = defaults.string(forKey: Keys.currentHandle) ?? ""
        self.recentHandles = defaults.stringArray(forKey: Keys.recentHandles) ?? []
        self.tmdbKey = defaults.string(forKey: Keys.tmdbKey) ?? ""
    }

    /// Called once at launch: show cached data immediately, then refresh.
    func bootstrap() async {
        if ProcessInfo.processInfo.environment["MISE_DEMO"] == "1" {
            library.loadSample(SampleData.history())
            return
        }
        guard !currentHandle.isEmpty else { return }
        await library.restoreCached(handle: currentHandle)
        await syncNow()
    }

    /// Switch to a different profile: record it, show its cached history at once,
    /// then re-scrape in the background.
    func switchTo(handle raw: String) async {
        let handle = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !handle.isEmpty else { return }
        if handle.lowercased() == "demo" {
            currentHandle = handle
            library.loadSample(SampleData.history())
            return
        }
        currentHandle = handle
        remember(handle)
        await library.restoreCached(handle: handle)
        await syncNow()
    }

    /// Re-scrape the current profile from Letterboxd.
    func syncNow() async {
        guard !currentHandle.isEmpty else { return }
        if currentHandle.lowercased() == "demo" {
            library.loadSample(SampleData.history())
            return
        }
        remember(currentHandle)
        await library.load(handle: currentHandle, tmdbKey: tmdbKey.isEmpty ? nil : tmdbKey)
        if let h = library.history {
            let posters = h.diary.filter { $0.film.posterURL != nil }.count
            FileHandle.standardError.write(Data("MISE diag: films=\(h.diary.count) withPoster=\(posters)\n".utf8))
        }
    }

    private func remember(_ handle: String) {
        var list = recentHandles.filter { $0.caseInsensitiveCompare(handle) != .orderedSame }
        list.insert(handle, at: 0)
        recentHandles = Array(list.prefix(8))
    }

    private static func makeStore() -> any HistoryStoring {
        if let persistent = try? LibraryStore() { return persistent }
        return try! LibraryStore(inMemory: true)
    }
}
