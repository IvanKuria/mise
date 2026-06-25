import SwiftUI
import MiseCore

/// A horizontal strip of the most recently logged films — poster, title, rating,
/// and a like heart. Renders on the black notch panel (clear background).
struct RecentlyWatchedPanel: View {
    let history: WatchHistory

    init(history: WatchHistory) { self.history = history }

    private var entries: [DiaryEntry] {
        var seen = Set<String>()
        let sorted = history.diary.sorted {
            ($0.watchedDate ?? $0.loggedDate ?? .distantPast) > ($1.watchedDate ?? $1.loggedDate ?? .distantPast)
        }
        var result: [DiaryEntry] = []
        for entry in sorted where seen.insert(entry.film.id).inserted {
            result.append(entry)
            if result.count == 7 { break }
        }
        return result
    }

    var body: some View {
        if entries.isEmpty {
            EmptyHint(symbol: "popcorn", text: "No films logged yet")
        } else {
            HStack(alignment: .top, spacing: 16) {
                ForEach(entries) { entry in
                    FilmCell(entry: entry)
                }
                Spacer(minLength: 0)
            }
        }
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
                HStack(spacing: 4) {
                    if showYear, let year = entry.film.releaseYear {
                        Text(String(year))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(NotchStyle.textSecondary)
                    }
                    if let rating = entry.rating {
                        Text(rating.starString)
                            .font(.system(size: 10))
                            .foregroundStyle(NotchStyle.star)
                            .lineLimit(1)
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
        .padding(20)
        .frame(width: 720, height: 200)
        .background(Color.black)
}
