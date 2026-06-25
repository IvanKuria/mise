import SwiftUI
import MiseCore

/// A small film poster (2:3) for the notch panels. Loads `film.posterURL`
/// (populated only when TMDB enrichment ran) and falls back to a dark
/// title/year placeholder.
struct FilmPoster: View {
    let film: Film
    var width: CGFloat = 56

    private static let aspect: CGFloat = 2.0 / 3.0
    private var height: CGFloat { width / Self.aspect }

    var body: some View {
        ZStack {
            if let url = film.posterURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    case .empty:
                        placeholder.overlay(ProgressView().controlSize(.mini).tint(NotchStyle.textTertiary))
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(NotchStyle.hairline, lineWidth: 1)
        )
    }

    private var placeholder: some View {
        ZStack {
            NotchStyle.surfaceElevated
            VStack(spacing: 2) {
                Text(film.name)
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(NotchStyle.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)
                if let year = film.releaseYear {
                    Text(String(year))
                        .font(.system(size: 7))
                        .foregroundStyle(NotchStyle.textTertiary)
                }
            }
            .padding(4)
        }
    }
}
