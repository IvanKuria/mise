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
            sidebar
                .navigationSplitViewColumnWidth(min: 60, ideal: 240, max: 300)
        } detail: {
            detail(for: app.section ?? .dashboard)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.clear)
        }
    }

    private var sidebar: some View {
        @Bindable var app = app
        let theme = MiseTheme(app.themeModel.theme)
        return ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing(0.5)) {
                ViewThatFits(in: .horizontal) {
                    Text("MISE")
                        .font(theme.font(.caption))
                        .tracking(2.5)
                        .foregroundStyle(theme.textTertiary)
                    Color.clear.frame(height: 0)
                }
                .padding(.horizontal, theme.spacing(1.5))
                .padding(.top, theme.spacing(1))
                .padding(.bottom, theme.spacing(1))

                ForEach(AppState.Section.allCases) { section in
                    let selected = (app.section ?? .dashboard) == section
                    MiseRow(isSelected: selected) {
                        ViewThatFits(in: .horizontal) {
                            // Full row when there's room…
                            HStack(spacing: theme.spacing(1.25)) {
                                icon(section, selected: selected, theme: theme)
                                Text(section.rawValue)
                                    .font(theme.font(.body).weight(selected ? .semibold : .regular))
                                    .foregroundStyle(selected ? theme.onSelection : theme.textPrimary)
                                    .lineLimit(1)
                                    .fixedSize()
                            }
                            // …icon only when the column is narrowed to a rail.
                            icon(section, selected: selected, theme: theme)
                                .frame(maxWidth: .infinity)
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

    private func icon(_ section: AppState.Section, selected: Bool, theme: MiseTheme) -> some View {
        Image(systemName: section.symbol)
            .font(.system(size: 14, weight: .medium))
            .frame(width: 18)
            .foregroundStyle(selected ? theme.onSelection : theme.textSecondary)
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
