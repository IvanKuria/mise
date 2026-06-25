import Foundation
import Observation
import OSLog
import ServiceManagement
import AppCore
import LocalStore
import MiseCore
import TMDBKit

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

    /// Short, user-facing message describing the last sync failure, or nil when
    /// the last sync succeeded / none has run. Observable so the UI can surface it.
    var syncErrorMessage: String?

    /// When the last successful (or attempted) sync completed; used by
    /// `refreshIfStale()` and the periodic auto-refresh.
    private(set) var lastSyncDate: Date?

    /// How stale data may get before `refreshIfStale()` re-syncs (~20 min).
    private let staleInterval: TimeInterval = 20 * 60
    /// Periodic background auto-refresh cadence (~30 min).
    private let autoRefreshInterval: TimeInterval = 30 * 60

    private var autoRefreshTimer: Timer?
    private let log = Logger(subsystem: "app.mise", category: "AppState")

    /// Cache of fetched TMDB details, keyed by tmdb id, for the film detail view.
    private var detailCache: [Int: TMDBMovie] = [:]

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
        startAutoRefresh()
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
        syncErrorMessage = nil
        if currentHandle.lowercased() == "demo" {
            library.loadSample(SampleData.history())
            lastSyncDate = Date()
            return
        }
        remember(currentHandle)
        await library.load(handle: currentHandle, tmdbKey: tmdbKey.isEmpty ? nil : tmdbKey)
        lastSyncDate = Date()
        // Map the controller's failure into a short, user-facing message.
        if case .failed(let msg) = library.phase {
            syncErrorMessage = Self.userFacingSyncError(msg, handle: currentHandle)
        } else {
            syncErrorMessage = nil
        }
    }

    /// Maps a raw pipeline failure message to a short message for the notch UI.
    private static func userFacingSyncError(_ raw: String, handle: String) -> String {
        let lower = raw.lowercased()
        if lower.contains("404") || lower.contains("not found") {
            return "Couldn't find @\(handle)"
        }
        if lower.contains("offline") || lower.contains("internet")
            || lower.contains("network") || lower.contains("cancel")
            || lower.contains("connection") || lower.contains("timed out")
            || lower.contains("timeout") {
            return "No internet connection"
        }
        return "Sync failed"
    }

    /// Re-sync only if the last sync is older than `staleInterval`. Guarded so two
    /// syncs never overlap (skips while a sync is already in flight).
    func refreshIfStale() async {
        guard !currentHandle.isEmpty, !isSyncing else { return }
        if let last = lastSyncDate, Date().timeIntervalSince(last) < staleInterval { return }
        await syncNow()
    }

    /// Starts the periodic background refresh (idempotent). Called from bootstrap.
    func startAutoRefresh() {
        guard autoRefreshTimer == nil else { return }
        let timer = Timer(timeInterval: autoRefreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, !self.isSyncing else { return }
                await self.syncNow()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        autoRefreshTimer = timer
    }

    // MARK: - Launch at login

    /// Whether the app is registered to launch at login.
    var launchAtLoginEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Register or unregister the app as a login item. Errors are logged, not thrown.
    func setLaunchAtLogin(_ on: Bool) {
        do {
            if on {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            log.error("Failed to set launch at login (on=\(on)): \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Fetches TMDB details (synopsis, runtime, genres) for a film, cached. Needs
    /// a TMDB key; returns nil without one or on failure.
    func filmDetail(tmdbID: Int?) async -> TMDBMovie? {
        guard let id = tmdbID, !tmdbKey.isEmpty else { return nil }
        if let cached = detailCache[id] { return cached }
        let client = TMDBClient(apiKey: tmdbKey)
        guard let movie = try? await client.movie(tmdbID: id) else { return nil }
        detailCache[id] = movie
        return movie
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
