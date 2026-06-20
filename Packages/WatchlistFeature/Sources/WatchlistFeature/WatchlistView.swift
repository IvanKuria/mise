import SwiftUI
import MiseCore
import MiseUI
import WatchlistPlanner
import ThemeKit

/// The Watchlist + "Tonight's Pick" surface: a prominent hero card with the
/// chosen film, criteria controls, and the filtered candidate poster wall.
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
                header

                TonightPickHero(model: model)

                CriteriaControls(model: model)

                candidatesSection
            }
            .padding(theme.spacing(3))
            .frame(maxWidth: 980, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(theme.background)
    }

    private var header: some View {
        SectionHeader(
            "Tonight",
            subtitle: model.pick == nil
                ? "Nothing matches yet"
                : "\(model.candidates.count) match your mood"
        )
    }

    @ViewBuilder
    private var candidatesSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing(1.5)) {
            SectionHeader(
                "Candidates",
                subtitle: model.hasActiveCriteria ? "Filtered" : "Your whole watchlist"
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
}

#Preview("WatchlistView") {
    WatchlistView(
        watchlist: WatchlistPreviewData.watchlist,
        availability: WatchlistPreviewData.availability
    )
    .frame(width: 900, height: 900)
    .miseTheme(.noir)
}
