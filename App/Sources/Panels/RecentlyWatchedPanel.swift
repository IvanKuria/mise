import SwiftUI
import MiseCore
import TMDBKit

/// A horizontal strip of the most recently logged films. Tapping a poster runs a
/// smooth matched-geometry transition into a `FilmDetailView` (poster left,
/// synopsis + info right). Renders on the black notch panel (clear background).
struct RecentlyWatchedPanel: View {
    @Environment(AppState.self) private var app
    let history: WatchHistory

    init(history: WatchHistory) { self.history = history }

    @Namespace private var ns
    @State private var selected: DiaryEntry?

    private var entries: [DiaryEntry] {
        var seen = Set<String>()
        let sorted = history.diary.sorted {
            ($0.watchedDate ?? $0.loggedDate ?? .distantPast) > ($1.watchedDate ?? $1.loggedDate ?? .distantPast)
        }
        var result: [DiaryEntry] = []
        for entry in sorted where seen.insert(entry.film.id).inserted {
            result.append(entry)
            if result.count == 9 { break }
        }
        return result
    }

    var body: some View {
        Group {
            if let sel = selected {
                FilmDetailView(entry: sel, namespace: ns, onClose: back)
            } else {
                grid
            }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.82), value: selected?.id)
    }

    // MARK: Grid

    @ViewBuilder
    private var grid: some View {
        if entries.isEmpty {
            EmptyHint(symbol: "popcorn", text: "No films logged yet")
        } else {
            HStack(alignment: .top, spacing: 14) {
                ForEach(entries) { entry in
                    cell(entry)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func cell(_ entry: DiaryEntry) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            FilmPoster(film: entry.film, width: NotchStyle.posterWidth)
                .matchedGeometryEffect(id: entry.id, in: ns)
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.film.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(NotchStyle.textPrimary)
                    .lineLimit(1)
                ratingRow(entry)
            }
            .frame(width: NotchStyle.posterWidth, alignment: .leading)
        }
        .contentShape(Rectangle())
        .onTapGesture { withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) { selected = entry } }
        .help(entry.film.name)
    }

    @ViewBuilder
    private func ratingRow(_ entry: DiaryEntry) -> some View {
        HStack(spacing: 4) {
            if let rating = entry.rating {
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 7, weight: .semibold))
                        .foregroundStyle(NotchStyle.star)
                    Text(String(format: "%g", rating.stars))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(NotchStyle.textSecondary)
                }
            }
            if entry.isLiked {
                Image(systemName: "heart.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(NotchStyle.heart)
            }
        }
    }

    // MARK: Helpers

    private func back() {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) { selected = nil }
    }
}

/// A poster with its title and rating beneath — shared cell for the film strips.
struct FilmCell: View {
    let entry: DiaryEntry
    var showYear: Bool = false
    @State private var hovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            FilmPoster(film: entry.film, width: NotchStyle.posterWidth)
                .scaleEffect(hovering ? 1.05 : 1)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hovering)
                .onHover { hovering = $0 }
                .help(entry.film.name + (entry.film.releaseYear.map { " (\($0))" } ?? ""))
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.film.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(NotchStyle.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 5) {
                    if showYear, let year = entry.film.releaseYear {
                        Text(String(year))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(NotchStyle.textSecondary)
                    }
                    if let rating = entry.rating {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 7, weight: .semibold))
                                .foregroundStyle(NotchStyle.star)
                            Text(String(format: "%g", rating.stars))
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(NotchStyle.textSecondary)
                        }
                    }
                    if entry.isLiked {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(NotchStyle.heart)
                    }
                }
            }
            .frame(width: NotchStyle.posterWidth, alignment: .leading)
        }
    }
}

/// A centered empty-state hint used by the panels.
struct EmptyHint: View {
    let symbol: String
    let text: String

    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(NotchStyle.textTertiary)
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(NotchStyle.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    RecentlyWatchedPanel(history: SampleData.history())
        .environment(AppState())
        .padding(20)
        .frame(width: 720, height: 220)
        .background(Color.black)
}
