import SwiftUI
import MiseCore
import MiseUI
import RecommenderEngine

/// "Compare your taste vs a friend." Renders a taste-affinity readout, the films
/// the two members disagree on most, and the films each loved that the other
/// hasn't seen — a scannable, themed comparison of two watch histories.
public struct CompareView: View {
    @Environment(\.miseTheme) private var theme

    private let model: CompareViewModel

    /// Build a comparison screen from two watch histories. The first is treated
    /// as "you", the second as your friend.
    public init(me: WatchHistory, other: WatchHistory) {
        self.model = CompareViewModel(
            me: me.member,
            other: other.member,
            comparison: compare(me, other)
        )
    }

    /// Inject a pre-built view model (used by tests and previews).
    public init(model: CompareViewModel) {
        self.model = model
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing(3)) {
                hero

                if model.hasOverlap {
                    statBand
                    if model.hasDisagreements {
                        card { disagreementsSection }
                    }
                    card {
                        recommendationSection(
                            title: "They loved, you haven’t seen",
                            subtitle: model.other.displayName,
                            films: model.forYou,
                            emptySymbol: "eye",
                            emptyMessage: "\(model.other.displayName) hasn’t loved anything new to you yet."
                        )
                    }
                    card {
                        recommendationSection(
                            title: "You loved, they haven’t seen",
                            subtitle: model.me.displayName,
                            films: model.forThem,
                            emptySymbol: "eye",
                            emptyMessage: "Nothing of yours \(model.other.displayName) is missing — yet."
                        )
                    }
                } else {
                    EmptyStateView(
                        symbol: "person.2.slash",
                        title: "No films in common",
                        message: "\(model.me.displayName) and \(model.other.displayName) haven’t rated any of the same films yet. Log a few overlapping titles to compare your tastes."
                    )
                    .frame(minHeight: 240)
                }
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
            Text("TASTE MATCH")
                .font(theme.font(.caption))
                .tracking(2.5)
                .foregroundStyle(theme.accent)
            Text("You vs \(model.other.displayName)")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(.bottom, theme.spacing(0.5))
    }

    // MARK: - Headline metrics

    private var statBand: some View {
        StatBand([
            StatItem(
                value: model.affinityPercentText,
                label: model.affinityCaption,
                emphasis: true
            ),
            StatItem(
                value: model.sharedFilmCountText,
                label: "Shared films"
            ),
        ])
    }

    // MARK: - Disagreements

    private var disagreementsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing(1.5)) {
            SectionHeader("Biggest disagreements", subtitle: "where your stars diverge")
            VStack(spacing: theme.spacing()) {
                ForEach(model.topDisagreements(), id: \.film.id) { disagreement in
                    DisagreementRow(
                        disagreement: disagreement,
                        deltaLabel: model.deltaLabel(for: disagreement)
                    )
                }
            }
        }
    }

    // MARK: - Recommendation poster shelves

    @ViewBuilder
    private func recommendationSection(
        title: String,
        subtitle: String,
        films: [Film],
        emptySymbol: String,
        emptyMessage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing(1.5)) {
            SectionHeader(title, subtitle: subtitle)
            if films.isEmpty {
                EmptyStateView(
                    symbol: emptySymbol,
                    title: "Nothing to suggest",
                    message: emptyMessage
                )
                .frame(minHeight: 160)
            } else {
                PosterWallView(films: films, style: .shelf)
            }
        }
    }
}

// MARK: - Disagreement row

/// One shared film with the two members' ratings two-up and the signed delta
/// highlighted.
struct DisagreementRow: View {
    @Environment(\.miseTheme) private var theme

    let disagreement: RatingDisagreement
    let deltaLabel: String

    /// Positive deltas (you rated it higher) lean accent; negative (they did)
    /// lean secondary accent — a quick read of who loved it more.
    private var deltaTint: Color {
        disagreement.ratingA.stars >= disagreement.ratingB.stars
            ? theme.accent
            : theme.secondaryAccent
    }

    var body: some View {
        HStack(spacing: theme.spacing(1.5)) {
            FilmPosterView(film: disagreement.film, width: 48)

            VStack(alignment: .leading, spacing: theme.spacing(0.5)) {
                Text(disagreement.film.name)
                    .font(theme.font(.body))
                    .foregroundStyle(theme.textPrimary)
                    .lineLimit(1)
                HStack(spacing: theme.spacing()) {
                    ratingColumn(label: "You", rating: disagreement.ratingA)
                    Rectangle()
                        .fill(theme.hairline)
                        .frame(width: 1, height: 18)
                    ratingColumn(label: "Them", rating: disagreement.ratingB)
                }
            }

            Spacer(minLength: 0)

            deltaBadge
        }
        .padding(theme.spacing())
        .background(
            RoundedRectangle(cornerRadius: theme.smallCornerRadius, style: .continuous)
                .fill(theme.recess)
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.smallCornerRadius, style: .continuous)
                .strokeBorder(theme.hairline, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(disagreement.film.name). You \(disagreement.ratingA.stars), them \(disagreement.ratingB.stars). Difference \(deltaLabel)."
        )
    }

    private func ratingColumn(label: String, rating: Rating) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(theme.font(.caption))
                .tracking(1.4)
                .foregroundStyle(theme.textTertiary)
                .lineLimit(1)
            StarRatingView(rating: rating, starSize: 13)
        }
    }

    private var deltaBadge: some View {
        Text(deltaLabel)
            .font(theme.font(.headline))
            .monospacedDigit()
            .foregroundStyle(deltaTint)
            .lineLimit(1)
            .padding(.horizontal, theme.spacing())
            .padding(.vertical, theme.spacing(0.5))
            .background(
                RoundedRectangle(cornerRadius: theme.smallCornerRadius, style: .continuous)
                    .fill(deltaTint.opacity(0.12))
            )
            .accessibilityHidden(true)
    }
}

// MARK: - Preview

#Preview("CompareView") {
    CompareView(me: CompareSampleData.me, other: CompareSampleData.other)
        .frame(width: 720, height: 900)
        .miseTheme(.noir)
}

#Preview("CompareView — no overlap") {
    CompareView(me: CompareSampleData.meNoOverlap, other: CompareSampleData.otherNoOverlap)
        .frame(width: 720, height: 600)
        .miseTheme(.noir)
}
