import SwiftUI
import MiseCore

/// The hero of the product: a film poster. Loads `film.posterURL` asynchronously
/// and falls back to a tasteful, themed title/year placeholder when no art exists.
public struct FilmPosterView: View {
    @Environment(\.miseTheme) private var theme

    private let film: Film
    private let width: CGFloat

    /// Standard 2:3 movie-poster aspect ratio.
    private static let aspectRatio: CGFloat = 2.0 / 3.0

    public init(film: Film, width: CGFloat) {
        self.film = film
        self.width = width
    }

    private var height: CGFloat { width / Self.aspectRatio }

    public var body: some View {
        ZStack {
            if let url = film.posterURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .empty:
                        loadingState
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                .strokeBorder(theme.posterBorder, lineWidth: 1)
        )
        .shadow(color: theme.posterShadow, radius: width * 0.06, x: 0, y: width * 0.03)
        .accessibilityElement()
        .accessibilityLabel(accessibilityText)
    }

    private var loadingState: some View {
        theme.surface
            .overlay(ProgressView().controlSize(.small).tint(theme.secondaryText))
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: [theme.surface, theme.background],
                startPoint: .top,
                endPoint: .bottom
            )
            VStack(spacing: theme.spacing(0.5)) {
                Text(film.name)
                    .font(theme.font(.headline))
                    .foregroundStyle(theme.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .minimumScaleFactor(0.6)
                if let year = film.releaseYear {
                    Text(String(year))
                        .font(theme.font(.caption))
                        .foregroundStyle(theme.secondaryText)
                }
            }
            .padding(theme.spacing(1.5))
        }
    }

    private var accessibilityText: String {
        if let year = film.releaseYear {
            return "\(film.name), \(year)"
        }
        return film.name
    }
}

#Preview("FilmPosterView") {
    HStack(spacing: 16) {
        FilmPosterView(film: MiseUIPreviewData.filmWithPoster, width: 120)
        FilmPosterView(film: MiseUIPreviewData.filmNoPoster, width: 120)
    }
    .padding(32)
    .background(MiseTheme(.noir).background)
    .miseTheme(.noir)
}
