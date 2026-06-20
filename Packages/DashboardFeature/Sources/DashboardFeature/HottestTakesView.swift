import SwiftUI
import MiseCore
import StatsEngine
import MiseUI

/// The "Hottest takes" gallery: the member's most contrarian films, each a small
/// poster with the member rating set against the crowd's.
struct HottestTakesView: View {
    @Environment(\.miseTheme) private var theme

    let takes: [FilmTakeDelta]
    /// Resolves a film id to its full `Film` for poster art.
    let film: (String) -> Film?

    private let posterWidth: CGFloat = 110

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: theme.spacing(2)) {
                ForEach(takes) { take in
                    takeCard(take)
                }
            }
            .padding(.vertical, theme.spacing(0.5))
        }
    }

    @ViewBuilder
    private func takeCard(_ take: FilmTakeDelta) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing(0.75)) {
            poster(for: take)
                .frame(width: posterWidth)

            VStack(alignment: .leading, spacing: 2) {
                ratingRow(label: "You", stars: take.memberStars, emphasised: true)
                ratingRow(label: "Crowd", stars: take.communityStars, emphasised: false)
                Text(deltaLabel(take.delta))
                    .font(theme.font(.caption))
                    .foregroundStyle(take.delta >= 0 ? theme.accent : theme.secondaryAccent)
            }
        }
        .frame(width: posterWidth)
    }

    @ViewBuilder
    private func poster(for take: FilmTakeDelta) -> some View {
        if let film = film(take.filmID) {
            FilmPosterView(film: film, width: posterWidth)
        } else {
            // Fallback to a synthesized film so the gallery never has holes.
            FilmPosterView(
                film: Film(id: take.filmID, name: take.filmName),
                width: posterWidth
            )
        }
    }

    private func ratingRow(label: String, stars: Double, emphasised: Bool) -> some View {
        HStack(spacing: theme.spacing(0.5)) {
            Text(label)
                .font(theme.font(.caption))
                .foregroundStyle(theme.secondaryText)
                .frame(width: theme.spacing(4), alignment: .leading)
            Text("\(DashboardFormat.decimal(stars, places: 1))★")
                .font(theme.font(.caption))
                .foregroundStyle(emphasised ? theme.primaryText : theme.secondaryText)
        }
    }

    private func deltaLabel(_ delta: Double) -> String {
        let magnitude = DashboardFormat.decimal(abs(delta), places: 1)
        return delta >= 0 ? "+\(magnitude) vs crowd" : "−\(magnitude) vs crowd"
    }
}
