import SwiftUI
import MiseCore
import MiseUI
import WatchlistPlanner
import ThemeKit

/// The Watchlist + "Tonight's Pick" surface: an editorial hero, a prominent
/// "Tonight's Pick" card, criteria controls, and the filtered candidate wall.
///
/// Mirrors Mise's established design language (see `DashboardView`): a `.clear`
/// root background, an eyebrow + bold title hero, and translucent `card { }`
/// sections at a generous spacing rhythm.
public struct WatchlistView: View {
    @Environment(\.miseTheme) private var theme
    @State private var model: WatchlistModel

    public init(
        watchlist: [WatchlistItem],
        availability: StreamingAvailability = .init()
    ) {
        _model = State(
            initialValue: WatchlistModel(
                watchlist: watchlist,
                availability: availability
            )
        )
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing(3)) {
                hero
                card { TonightPickHero(model: model) }
                card { CriteriaControls(model: model) }
                card { candidatesSection }
            }
            .padding(theme.spacing(4))
            .frame(maxWidth: 980, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(.clear)
    }

    /// Wraps a section in a translucent card for grouping and depth.
    private func card<V: View>(@ViewBuilder _ content: () -> V) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(theme.spacing(2.5))
            .miseCard(theme)
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: theme.spacing(0.75)) {
            Text("TONIGHT")
                .font(theme.font(.caption))
                .tracking(2.5)
                .foregroundStyle(theme.accent)
            Text("What to watch")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(theme.textPrimary)
        }
        .padding(.bottom, theme.spacing(0.5))
    }

    // MARK: - Candidates

    @ViewBuilder
    private var candidatesSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing(1.5)) {
            SectionHeader(
                "Candidates",
                subtitle: candidatesSubtitle
            )

            if model.candidates.isEmpty {
                EmptyStateView(
                    symbol: "popcorn",
                    title: "No films fit tonight",
                    message: "Loosen a filter — raise the runtime cap, drop a genre, or lower the rating floor."
                )
                .frame(minHeight: 240)
            } else {
                PosterWallView(films: model.candidates.map(\.film), style: .grid)
            }
        }
    }

    private var candidatesSubtitle: String {
        let count = model.candidates.count
        let noun = count == 1 ? "film" : "films"
        if model.hasActiveCriteria {
            return "\(count) \(noun) match"
        }
        return "\(count) \(noun) on your watchlist"
    }
}

#Preview("WatchlistView") {
    WatchlistView(
        watchlist: WatchlistPreviewData.watchlist,
        availability: WatchlistPreviewData.availability
    )
    .frame(width: 900, height: 900)
    .miseTheme(.noir)
}
