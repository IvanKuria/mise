import SwiftUI
import MiseCore
import TMDBKit

/// A reusable, self-contained detail view for a single diary entry. Presents an
/// enlarged poster on the left (matched-geometry from the panel grid) and the
/// film's full title, meta line, TMDB synopsis and genres on the right.
///
/// A blurred, scaled copy of the poster bleeds behind the content as a subtle
/// ambient "album-art" glow (boring.notch style), clipped to the panel bounds.
///
/// Owns its own TMDB fetch via `app.filmDetail(tmdbID:)`. Tapping the poster or
/// the ✕ button calls `onClose`.
struct FilmDetailView: View {
    @Environment(AppState.self) private var app

    let entry: DiaryEntry
    var namespace: Namespace.ID
    var onClose: () -> Void

    @State private var detail: TMDBMovie?
    @State private var loadingDetail = false

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            FilmPoster(film: entry.film, width: 84)
                .matchedGeometryEffect(id: entry.id, in: namespace)
                .onTapGesture { onClose() }
                .help("Back")

            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .top, spacing: 8) {
                    Text(entry.film.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(NotchStyle.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    HoverButton(systemName: "xmark", size: 22, fontSize: 10) { onClose() }
                }
                metaRow
                synopsis
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(bloom)
        .task(id: entry.id) { await loadDetail() }
    }

    // MARK: Poster bloom

    /// A blurred, scaled, low-opacity copy of the poster behind the content for an
    /// ambient color glow. Clipped to the panel so it never leaks outside the notch.
    private var bloom: some View {
        FilmPoster(film: entry.film, width: 84)
            .scaleEffect(1.3)
            .blur(radius: 40)
            .opacity(0.35)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .clipped()
            .allowsHitTesting(false)
    }

    // MARK: Meta

    private var metaRow: some View {
        HStack(spacing: 8) {
            if let year = entry.film.releaseYear {
                Text(String(year)).foregroundStyle(NotchStyle.textSecondary)
            }
            ratingRow
            if let runtime = detail?.runtime, runtime > 0 {
                Text("· \(runtime / 60)h \(runtime % 60)m").foregroundStyle(NotchStyle.textTertiary)
            }
            if let date = entry.watchedDate {
                Text("· \(Self.dateFormatter.string(from: date))").foregroundStyle(NotchStyle.textTertiary)
            }
        }
        .font(.system(size: 11, weight: .medium))
        .lineLimit(1)
    }

    @ViewBuilder
    private var ratingRow: some View {
        HStack(spacing: 4) {
            if let rating = entry.rating {
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(NotchStyle.star)
                    Text(String(format: "%g", rating.stars))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(NotchStyle.textSecondary)
                }
            }
            if entry.isLiked {
                Image(systemName: "heart.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(NotchStyle.heart)
            }
        }
    }

    // MARK: Synopsis

    @ViewBuilder
    private var synopsis: some View {
        if loadingDetail && detail == nil {
            Text("Loading…")
                .font(.system(size: 12))
                .foregroundStyle(NotchStyle.textTertiary)
        } else if let overview = detail?.overview, !overview.isEmpty {
            VStack(alignment: .leading, spacing: 5) {
                if !(detail?.genres.isEmpty ?? true) {
                    Text(detail!.genres.prefix(3).joined(separator: " · "))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(NotchStyle.textTertiary)
                }
                Text(overview)
                    .font(.system(size: 12))
                    .foregroundStyle(NotchStyle.textSecondary)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } else if let review = entry.review, !review.isEmpty {
            Text("“\(review)”")
                .font(.system(size: 12))
                .italic()
                .foregroundStyle(NotchStyle.textSecondary)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Text(app.tmdbKey.isEmpty ? "Add a TMDB key in Settings for synopses." : "No synopsis available.")
                .font(.system(size: 12))
                .foregroundStyle(NotchStyle.textTertiary)
        }
    }

    // MARK: Loading

    private func loadDetail() async {
        detail = nil
        loadingDetail = true
        detail = await app.filmDetail(tmdbID: entry.film.tmdbID)
        loadingDetail = false
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f
    }()
}
