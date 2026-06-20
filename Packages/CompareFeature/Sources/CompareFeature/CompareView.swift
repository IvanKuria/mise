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
                header

                if model.hasOverlap {
                    if model.hasDisagreements {
                        disagreementsSection
                    }
                    recommendationSection(
                        title: "They loved, you haven’t seen",
                        subtitle: model.other.displayName,
                        films: model.forYou,
                        emptySymbol: "eye",
                        emptyMessage: "\(model.other.displayName) hasn’t loved anything new to you yet."
                    )
                    recommendationSection(
                        title: "You loved, they haven’t seen",
                        subtitle: model.me.displayName,
                        films: model.forThem,
                        emptySymbol: "eye",
                        emptyMessage: "Nothing of yours \(model.other.displayName) is missing — yet."
                    )
                } else {
                    EmptyStateView(
                        symbol: "person.2.slash",
                        title: "No films in common",
                        message: "\(model.me.displayName) and \(model.other.displayName) haven’t rated any of the same films yet. Log a few overlapping titles to compare your tastes."
                    )
                    .frame(minHeight: 240)
                }
            }
            .padding(theme.spacing(3))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(theme.background)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: theme.spacing(2)) {
            HStack(alignment: .center, spacing: theme.spacing(2)) {
                MemberBadge(member: model.me, caption: "You")
                Text("vs")
                    .font(theme.font(.headline))
                    .foregroundStyle(theme.secondaryText)
                MemberBadge(member: model.other, caption: "@\(model.other.username)")
                Spacer(minLength: 0)
            }

            HStack(alignment: .top, spacing: theme.spacing(2)) {
                StatCard(
                    title: "Taste affinity",
                    value: model.affinityPercentText,
                    caption: model.affinityCaption
                )
                StatCard(
                    title: "Shared films",
                    value: model.sharedFilmCountText,
                    caption: "rated by both"
                )
            }
        }
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

    // MARK: - Recommendation poster rows

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

// MARK: - Member badge

/// A circular avatar (or themed monogram fallback) with name and caption.
struct MemberBadge: View {
    @Environment(\.miseTheme) private var theme

    let member: MemberSummary
    let caption: String

    private var monogram: String {
        String(member.displayName.first.map(String.init) ?? "?").uppercased()
    }

    var body: some View {
        HStack(spacing: theme.spacing()) {
            avatar
            VStack(alignment: .leading, spacing: 0) {
                Text(member.displayName)
                    .font(theme.font(.headline))
                    .foregroundStyle(theme.primaryText)
                    .lineLimit(1)
                Text(caption)
                    .font(theme.font(.caption))
                    .foregroundStyle(theme.secondaryText)
                    .lineLimit(1)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var avatar: some View {
        ZStack {
            Circle().fill(theme.surface)
            Circle().strokeBorder(theme.posterBorder, lineWidth: 1)
            if let url = member.avatarURL {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    monogramText
                }
                .clipShape(Circle())
            } else {
                monogramText
            }
        }
        .frame(width: 44, height: 44)
    }

    private var monogramText: some View {
        Text(monogram)
            .font(theme.font(.headline))
            .foregroundStyle(theme.accent)
    }
}

// MARK: - Disagreement row

/// One shared film with the two members' ratings two-up and the signed delta
/// highlighted.
struct DisagreementRow: View {
    @Environment(\.miseTheme) private var theme

    let disagreement: RatingDisagreement
    let deltaLabel: String

    var body: some View {
        HStack(spacing: theme.spacing(1.5)) {
            FilmPosterView(film: disagreement.film, width: 48)

            VStack(alignment: .leading, spacing: theme.spacing(0.5)) {
                Text(disagreement.film.name)
                    .font(theme.font(.body))
                    .foregroundStyle(theme.primaryText)
                    .lineLimit(1)
                HStack(spacing: theme.spacing()) {
                    ratingColumn(label: "You", rating: disagreement.ratingA)
                    Divider().frame(height: 18)
                    ratingColumn(label: "Them", rating: disagreement.ratingB)
                }
            }

            Spacer(minLength: 0)

            deltaBadge
        }
        .padding(theme.spacing())
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                .fill(theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                .strokeBorder(theme.posterBorder.opacity(0.6), lineWidth: 1)
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
                .tracking(0.6)
                .foregroundStyle(theme.secondaryText)
            StarRatingView(rating: rating, starSize: 13)
        }
    }

    private var deltaBadge: some View {
        Text(deltaLabel)
            .font(theme.font(.headline))
            .monospacedDigit()
            .foregroundStyle(theme.accent)
            .padding(.horizontal, theme.spacing())
            .padding(.vertical, theme.spacing(0.5))
            .background(
                RoundedRectangle(cornerRadius: theme.smallCornerRadius, style: .continuous)
                    .fill(theme.accent.opacity(0.12))
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
