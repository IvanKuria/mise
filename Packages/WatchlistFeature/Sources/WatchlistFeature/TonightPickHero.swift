import SwiftUI
import MiseCore
import MiseUI
import WatchlistPlanner

/// The hero of the screen: a large poster of tonight's pick, a "why" line, and a
/// prominent Reroll button. Designed to sit inside a translucent `miseCard`, so
/// it carries no background of its own. Shows a themed empty state when nothing
/// matches.
struct TonightPickHero: View {
    @Environment(\.miseTheme) private var theme
    @Bindable var model: WatchlistModel

    private let posterWidth: CGFloat = 200

    var body: some View {
        Group {
            if let pick = model.pick {
                content(for: pick)
            } else {
                emptyHero
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.snappy(duration: 0.28), value: model.pick)
    }

    private func content(for pick: WatchlistItem) -> some View {
        HStack(alignment: .top, spacing: theme.spacing(3)) {
            FilmPosterView(film: pick.film, width: posterWidth)
                .id(pick.id)
                .transition(.scale(scale: 0.94).combined(with: .opacity))

            VStack(alignment: .leading, spacing: theme.spacing(1.5)) {
                Text("TONIGHT'S PICK")
                    .font(theme.font(.caption))
                    .tracking(2.5)
                    .foregroundStyle(theme.accent)

                Text(pick.film.name)
                    .font(theme.font(.largeTitle))
                    .foregroundStyle(theme.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                    .fixedSize(horizontal: false, vertical: true)

                let meta = PickRationale.metaLine(for: pick.film)
                if !meta.isEmpty {
                    Text(meta)
                        .font(theme.font(.body))
                        .foregroundStyle(theme.textSecondary)
                        .lineLimit(1)
                }

                if !pick.film.genres.isEmpty {
                    genreChips(for: pick.film)
                }

                Text(PickRationale.reason(
                    for: pick,
                    criteria: model.criteria,
                    availability: model.availabilitySnapshot,
                    ranking: model.ranking
                ))
                .font(theme.font(.body))
                .foregroundStyle(theme.textSecondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: theme.spacing())

                rerollButton
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func genreChips(for film: Film) -> some View {
        HStack(spacing: theme.spacing(0.75)) {
            ForEach(film.genres.prefix(3)) { genre in
                Chip(genre.name)
            }
        }
    }

    private var rerollButton: some View {
        Button {
            model.reroll()
        } label: {
            HStack(spacing: theme.spacing(0.75)) {
                Image(systemName: "dice")
                Text("Reroll")
            }
            .font(theme.font(.headline))
            .foregroundStyle(theme.onSelection)
            .padding(.horizontal, theme.spacing(2))
            .padding(.vertical, theme.spacing(1.25))
            .background(
                Capsule(style: .continuous).fill(theme.accent)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Reroll tonight's pick")
    }

    private var emptyHero: some View {
        EmptyStateView(
            symbol: "moon.stars",
            title: "No pick yet",
            message: "Adjust your criteria below and a film for tonight will appear here."
        )
        .frame(minHeight: posterWidth * 1.2)
    }
}
