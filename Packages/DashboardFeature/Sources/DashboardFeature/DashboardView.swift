import SwiftUI
import MiseCore
import StatsEngine
import MiseUI

/// The stats dashboard — the centerpiece of Mise. Renders a member's full
/// analytics: headline metrics, a ratings histogram, a watching heatmap, genre
/// and decade breakdowns, top directors and cast, and the member's hottest takes.
///
/// Construct from a `WatchHistory` (stats are computed internally via
/// `StatsEngine`) or from a precomputed `FilmStats` plus a film lookup.
public struct DashboardView: View {
    @Environment(\.miseTheme) private var theme

    private let stats: FilmStats
    private let displayName: String
    /// Resolves a film id to its full `Film` for poster art in the takes gallery.
    private let filmLookup: (String) -> Film?

    /// Build from a member's watch history; stats are computed with `StatsEngine`.
    public init(history: WatchHistory, options: StatsOptions = .default) {
        self.stats = StatsEngine.compute(history, options: options)
        self.displayName = history.member.displayName
        let byID = Dictionary(history.diary.map { ($0.film.id, $0.film) }) { first, _ in first }
        self.filmLookup = { byID[$0] }
    }

    /// Build from precomputed stats. `filmLookup` supplies poster art for the
    /// hottest-takes gallery; defaults to none (synthesized placeholders).
    public init(
        stats: FilmStats,
        displayName: String = "",
        filmLookup: @escaping (String) -> Film? = { _ in nil }
    ) {
        self.stats = stats
        self.displayName = displayName
        self.filmLookup = filmLookup
    }

    public var body: some View {
        Group {
            if stats.totalLogged == 0 {
                EmptyStateView(
                    symbol: "chart.bar.xaxis",
                    title: "No stats yet",
                    message: "Sync your Letterboxd diary to unlock your viewing stats."
                )
            } else {
                content
            }
        }
        .background(theme.background.ignoresSafeArea())
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing(4)) {
                headline
                headlineCards
                ratingsSection
                heatmapSection
                breakdownsSection
                peopleSection
                hottestTakesSection
            }
            .padding(theme.spacing(4))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Sections

    private var headline: some View {
        VStack(alignment: .leading, spacing: theme.spacing(0.5)) {
            Text(displayName.isEmpty ? "Your year in film" : "\(displayName)'s year in film")
                .font(theme.font(.largeTitle))
                .foregroundStyle(theme.primaryText)
            Text("A look across everything you've logged.")
                .font(theme.font(.body))
                .foregroundStyle(theme.secondaryText)
        }
    }

    private var headlineCards: some View {
        let columns = [GridItem(.adaptive(minimum: 160), spacing: theme.spacing(2))]
        return LazyVGrid(columns: columns, spacing: theme.spacing(2)) {
            StatCard(
                title: "Films logged",
                value: DashboardFormat.count(stats.totalLogged),
                caption: "\(DashboardFormat.count(stats.distinctFilmCount)) unique"
            )
            StatCard(
                title: "Days of runtime",
                value: DashboardFormat.runtimeDays(minutes: stats.totalRuntimeMinutes),
                caption: DashboardFormat.runtimeHoursCaption(minutes: stats.totalRuntimeMinutes)
            )
            StatCard(
                title: "Average rating",
                value: DashboardFormat.averageStarsLabel(DashboardFormat.averageStars(histogram: stats.ratingsHistogram)),
                caption: "\(DashboardFormat.count(stats.likedCount)) liked"
            )
            StatCard(
                title: "Contrarian score",
                value: DashboardFormat.contrarianLabel(stats.contrarianScore),
                caption: DashboardFormat.contrarianCaption(stats.contrarianScore)
            )
        }
    }

    private var ratingsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing(1.5)) {
            SectionHeader("Ratings", subtitle: "How you score films")
            RatingsHistogramView(histogram: stats.ratingsHistogram)
        }
    }

    @ViewBuilder
    private var heatmapSection: some View {
        let counts = DashboardFormat.heatmapCounts(stats)
        VStack(alignment: .leading, spacing: theme.spacing(1.5)) {
            SectionHeader(
                "Watching activity",
                subtitle: "Longest streak: \(stats.longestStreakDays) day\(stats.longestStreakDays == 1 ? "" : "s")"
            )
            if counts.isEmpty {
                Text("No dated diary entries to map yet.")
                    .font(theme.font(.body))
                    .foregroundStyle(theme.secondaryText)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HeatmapGridView(counts: counts)
                        .padding(.vertical, theme.spacing(0.5))
                }
            }
        }
    }

    private var breakdownsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing(2)) {
            VStack(alignment: .leading, spacing: theme.spacing(1.5)) {
                SectionHeader("Genres", subtitle: "What you reach for")
                GenreBreakdownView(bars: DashboardFormat.genreBars(stats.genreBreakdown))
            }
            VStack(alignment: .leading, spacing: theme.spacing(1.5)) {
                SectionHeader("Decades", subtitle: "When your films were made")
                DecadeBreakdownView(bars: DashboardFormat.decadeBars(stats.decadeBreakdown))
            }
        }
    }

    private var peopleSection: some View {
        let columns = [GridItem(.adaptive(minimum: 280), spacing: theme.spacing(3))]
        return LazyVGrid(columns: columns, alignment: .leading, spacing: theme.spacing(3)) {
            VStack(alignment: .leading, spacing: theme.spacing(1.5)) {
                SectionHeader("Top directors")
                PeopleListView(people: stats.topDirectors)
            }
            VStack(alignment: .leading, spacing: theme.spacing(1.5)) {
                SectionHeader("Top cast")
                PeopleListView(people: stats.topCast)
            }
        }
    }

    @ViewBuilder
    private var hottestTakesSection: some View {
        if !stats.hottestTakes.isEmpty {
            VStack(alignment: .leading, spacing: theme.spacing(1.5)) {
                SectionHeader("Hottest takes", subtitle: "Where you split from the crowd")
                HottestTakesView(takes: stats.hottestTakes, film: filmLookup)
            }
        }
    }
}

#Preview("Dashboard") {
    DashboardView(history: DashboardSampleData.history)
        .miseTheme(.noir)
        .frame(width: 900, height: 1100)
}

#Preview("Dashboard — Empty") {
    DashboardView(history: DashboardSampleData.emptyHistory)
        .miseTheme(.noir)
        .frame(width: 900, height: 600)
}
