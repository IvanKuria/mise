import SwiftUI
import MiseCore
import MiseUI
import DashboardFeature
import BrowseFeature
import WatchlistFeature
import ThemeStudioFeature

/// The main window once a member's history is loaded: a translucent sidebar that
/// collapses to an icon rail, and the selected feature in the detail pane.
struct MainShell: View {
    @Environment(AppState.self) private var app
    let history: WatchHistory

    var body: some View {
        @Bindable var app = app
        NavigationSplitView {
            GeometryReader { geo in
                sidebar(compact: geo.size.width < 150)
            }
            .navigationSplitViewColumnWidth(min: 64, ideal: 240, max: 300)
        } detail: {
            detail(for: app.section ?? .dashboard)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.clear)
        }
    }

    @ViewBuilder
    private func sidebar(compact: Bool) -> some View {
        @Bindable var app = app
        let theme = MiseTheme(app.themeModel.theme)
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing(0.5)) {
                if !compact {
                    Text("MISE")
                        .font(theme.font(.caption))
                        .tracking(2.5)
                        .foregroundStyle(theme.textTertiary)
                        .padding(.horizontal, theme.spacing(1.5))
                        .padding(.top, theme.spacing(1))
                        .padding(.bottom, theme.spacing(1.5))
                }

                ForEach(AppState.Section.allCases) { section in
                    let selected = (app.section ?? .dashboard) == section
                    MiseRow(isSelected: selected) {
                        if compact {
                            Image(systemName: section.symbol)
                                .font(.system(size: 15, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .foregroundStyle(selected ? theme.onSelection : theme.textSecondary)
                        } else {
                            HStack(spacing: theme.spacing(1.25)) {
                                Image(systemName: section.symbol)
                                    .font(.system(size: 14, weight: .medium))
                                    .frame(width: 18)
                                    .foregroundStyle(selected ? theme.onSelection : theme.textSecondary)
                                Text(section.rawValue)
                                    .font(theme.font(.body).weight(selected ? .semibold : .regular))
                                    .foregroundStyle(selected ? theme.onSelection : theme.textPrimary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .help(section.rawValue)
                    .onTapGesture { app.section = section }
                }
            }
            .padding(theme.spacing(1))
        }
        .scrollContentBackground(.hidden)
        .background(.clear)
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
        case .themeStudio:
            ThemeStudioView(model: app.themeModel)
        }
    }
}
