import Foundation
import Observation
import AppCore
import LocalStore
import ThemeKit
import ThemeStudioFeature

/// App-wide state: the data pipeline controller, the active theme model, and the
/// selected sidebar section. `@Observable` so SwiftUI re-renders on any change
/// (including live theme edits in the Theme Studio).
@MainActor
@Observable
final class AppState {
    let library: LibraryController
    let themeModel = ThemeStudioModel(theme: .repertory)
    var section: Section? = .dashboard

    enum Section: String, CaseIterable, Identifiable, Hashable {
        case dashboard = "Dashboard"
        case browse = "Browse"
        case compare = "Compare"
        case watchlist = "Watchlist"
        case tasteCard = "Taste DNA"
        case themeStudio = "Theme"

        var id: String { rawValue }

        var symbol: String {
            switch self {
            case .dashboard: "chart.bar.xaxis"
            case .browse: "square.grid.3x3.fill"
            case .compare: "person.2.fill"
            case .watchlist: "die.face.5.fill"
            case .tasteCard: "sparkles"
            case .themeStudio: "paintpalette.fill"
            }
        }
    }

    init() {
        // Persistent store on disk; fall back to in-memory if the container
        // can't be created (e.g. a sandboxed first run with no container yet).
        let store: any HistoryStoring = AppState.makeStore()
        self.library = LibraryController(store: store)
    }

    private static func makeStore() -> any HistoryStoring {
        if let persistent = try? LibraryStore() { return persistent }
        // Last-resort in-memory store so the app still launches.
        return try! LibraryStore(inMemory: true)
    }
}
