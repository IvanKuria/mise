import SwiftUI
import MiseCore
import TMDBKit

/// A horizontal strip of the most recently logged films. Tapping a poster runs a
/// smooth matched-geometry transition into a detail view (poster left, synopsis +
/// info right). Renders on the black notch panel (clear background).
struct RecentlyWatchedPanel: View {
    @Environment(AppState.self) private var app
    let history: WatchHistory

    init(history: WatchHistory) { self.history = history }

    @Namespace private var ns
    @State private var selected: DiaryEntry?
    @State private var detail: TMDBMovie?
    @State private var loadingDetail = false

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
                detailView(sel)
            } else {
                grid
            }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.82), value: selected?.id)
        .task(id: selected?.id) { await loadDetail() }
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
                ratingRow(entry, compact: true)
            }
            .frame(width: NotchStyle.posterWidth, alignment: .leading)
        }
        .contentShape(Rectangle())
        .onTapGesture { withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) { selected = entry } }
        .help(entry.film.name)
    }

    // MARK: Detail

    private func detailView(_ entry: DiaryEntry) -> some View {
        HStack(alignment: .top, spacing: 16) {
            FilmPoster(film: entry.film, width: 84)
                .matchedGeometryEffect(id: entry.id, in: ns)
                .onTapGesture { back() }

            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .top, spacing: 8) {
                    Text(entry.film.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(NotchStyle.textPrimary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    HoverButton(systemName: "xmark", size: 22, fontSize: 10) { back() }
                }
                metaRow(entry)
                synopsis
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func metaRow(_ entry: DiaryEntry) -> some View {
        HStack(spacing: 8) {
            if let year = entry.film.releaseYear {
                Text(String(year)).foregroundStyle(NotchStyle.textSecondary)
            }
            ratingRow(entry, compact: false)
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
    private func ratingRow(_ entry: DiaryEntry, compact: Bool) -> some View {
        HStack(spacing: 4) {
            if let rating = entry.rating {
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.system(size: compact ? 7 : 8, weight: .semibold))
                        .foregroundStyle(NotchStyle.star)
                    Text(String(format: "%g", rating.stars))
                        .font(.system(size: compact ? 10 : 11, weight: .semibold))
                        .foregroundStyle(NotchStyle.textSecondary)
                }
            }
            if entry.isLiked {
                Image(systemName: "heart.fill")
                    .font(.system(size: compact ? 8 : 9))
                    .foregroundStyle(NotchStyle.heart)
            }
        }
    }

    @ViewBuilder
    private var synopsis: some View {
        if loadingDetail && detail == nil {
            Text("Loading synopsis…")
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
        } else if let review = entry(for: selected)?.review, !review.isEmpty {
            Text("“\(review)”")
                .font(.system(size: 12))
                .italic()
                .foregroundStyle(NotchStyle.textSecondary)
                .lineLimit(4)
        } else {
            Text(app.tmdbKey.isEmpty ? "Add a TMDB key in Settings for synopses." : "No synopsis available.")
                .font(.system(size: 12))
                .foregroundStyle(NotchStyle.textTertiary)
        }
    }

    // MARK: Helpers

    private func entry(for selected: DiaryEntry?) -> DiaryEntry? { selected }

    private func select(_ entry: DiaryEntry) {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) { selected = entry }
    }

    private func back() {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) { selected = nil }
    }

    private func loadDetail() async {
        guard let entry = selected else { detail = nil; return }
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
