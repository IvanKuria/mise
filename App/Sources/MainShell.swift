import SwiftUI
import MiseCore
import MiseUI
import DashboardFeature
import BrowseFeature
import WatchlistFeature
import TasteCardFeature
import ThemeStudioFeature

/// The main window once a member's history is loaded: a sidebar of sections and
/// the selected feature in the detail pane.
struct MainShell: View {
    @Environment(AppState.self) private var app
    let history: WatchHistory

    var body: some View {
        @Bindable var app = app
        NavigationSplitView {
            List(AppState.Section.allCases, selection: $app.section) { section in
                Label(section.rawValue, systemImage: section.symbol)
                    .tag(section)
            }
            .navigationTitle("Mise")
            .navigationSplitViewColumnWidth(min: 200, ideal: 220)
        } detail: {
            detail(for: app.section ?? .dashboard)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func detail(for section: AppState.Section) -> some View {
        switch section {
        case .dashboard:
            DashboardView(history: history)
        case .browse:
            BrowseView(entries: history.diary)
        case .compare:
            CompareLoaderView(me: history)
        case .watchlist:
            WatchlistView(watchlist: history.watchlist)
        case .tasteCard:
            TasteCardScreen(history: history, theme: app.themeModel.theme)
        case .themeStudio:
            ThemeStudioView(model: app.themeModel)
        }
    }
}
