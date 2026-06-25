import Foundation
import MiseCore

/// Reads PUBLIC Letterboxd profile data by scraping the website. The handle is
/// used as the member id throughout (Letterboxd URLs are keyed by handle).
///
/// Method signatures match `LocalStore.LetterboxdFetching` so the app can declare
/// `extension ScrapingFetcher: LetterboxdFetching {}` without this package
/// depending on LocalStore.
public actor ScrapingFetcher {
    private let fetcher: HTMLFetching
    /// Fetcher used for the JavaScript-lazy `/films/` grid (a real browser engine
    /// is needed to render it). Defaults to `fetcher` when not supplied.
    private let gridFetcher: HTMLFetching
    /// Hard cap on pages walked for any single paginated section, to stay polite.
    private let maxPages: Int
    /// Hard cap on lists whose films we fetch, to stay polite.
    private let maxListFilmFetches: Int

    public init(fetcher: HTMLFetching, gridFetcher: HTMLFetching? = nil, maxPages: Int = 50, maxListFilmFetches: Int = 0) {
        self.fetcher = fetcher
        self.gridFetcher = gridFetcher ?? fetcher
        self.maxPages = maxPages
        self.maxListFilmFetches = maxListFilmFetches
    }

    /// Convenience initialiser building a live `URLSessionHTMLFetcher`.
    public init(politeness: PolitenessConfig = PolitenessConfig(), maxPages: Int = 50, maxListFilmFetches: Int = 0) {
        let urlSession = URLSessionHTMLFetcher(config: politeness)
        self.fetcher = urlSession
        self.gridFetcher = urlSession
        self.maxPages = maxPages
        self.maxListFilmFetches = maxListFilmFetches
    }

    // MARK: - Profile

    public func member(username: String) async throws -> MemberSummary {
        let html = try await fetcher.html(for: LetterboxdURLs.profile(username))
        return try LetterboxdParser.member(html, username: username)
    }

    public func statistics(memberID: String) async throws -> MemberStatistics {
        let html = try await fetcher.html(for: LetterboxdURLs.profile(memberID))
        let base = try LetterboxdParser.statistics(html)
        // Derive a watched count and ratings histogram from the films grid when
        // the header doesn't already carry everything we want.
        let films = try await allFilms(memberID: memberID)
        var histogram: [Int: Int] = [:]
        for entry in films {
            if let r = entry.rating { histogram[r.halfStars, default: 0] += 1 }
        }
        return MemberStatistics(
            watchedFilmCount: base.watchedFilmCount > 0 ? base.watchedFilmCount : films.count,
            diaryEntryCount: base.diaryEntryCount,
            listCount: base.listCount,
            followerCount: base.followerCount,
            followingCount: base.followingCount,
            ratingsHistogram: histogram
        )
    }

    // MARK: - Diary

    /// Diary / log entries. `perPage` is informational (Letterboxd fixes diary
    /// page size); `cursor` is an optional 1-based page number as a string.
    public func logEntries(memberID: String, perPage: Int = 50, cursor: String? = nil) async throws -> [DiaryEntry] {
        // Primary source: the RSS feed. It's reliable (no Cloudflare challenge, no
        // JS-lazy grid), structured, and already carries watched dates, ratings,
        // like/rewatch flags, and poster URLs.
        let rss: [DiaryEntry]
        if let xml = try? await fetcher.html(for: LetterboxdURLs.rss(memberID)) {
            rss = LetterboxdRSS.entries(xml, username: memberID)
        } else {
            rss = []
        }

        // Secondary: the diary HTML (page 1 is reliable; deeper pages are
        // Cloudflare-limited). Adds anything the RSS window missed.
        let startPage = cursor.flatMap(Int.init) ?? 1
        var diary: [DiaryEntry] = []
        if let entries = try? await paginate(startPage: startPage, fetch: { page -> ([DiaryEntry], Int) in
            let html = try await fetcher.html(for: LetterboxdURLs.diary(memberID, page: page))
            return (try LetterboxdParser.diaryEntries(html), try LetterboxdParser.totalPages(in: html))
        }) {
            diary = entries
        }

        // Tertiary: the /films/ grid for additional rated films (often empty for
        // unauthenticated clients because it renders lazily; harmless when so).
        let grid: [DiaryEntry] = (try? await allFilms(memberID: memberID)) ?? []

        // Merge, preferring richer sources first (RSS has poster + date).
        var seen = Set<String>()
        var merged: [DiaryEntry] = []
        for entry in rss + diary + grid where seen.insert(entry.film.id).inserted {
            merged.append(entry)
        }
        return merged
    }

    // MARK: - Films grid

    /// All watched/rated films from the `/{user}/films/` grid (richer than diary
    /// for ratings coverage). Returned as `DiaryEntry` (no watched date).
    public func films(memberID: String) async throws -> [DiaryEntry] {
        try await allFilms(memberID: memberID)
    }

    private func allFilms(memberID: String) async throws -> [DiaryEntry] {
        try await paginate(startPage: 1) { page in
            // The grid renders posters via React, so use the browser-engine fetcher.
            let html = try await gridFetcher.html(for: LetterboxdURLs.films(memberID, page: page))
            return (try LetterboxdParser.filmsGrid(html), try LetterboxdParser.totalPages(in: html))
        }
    }

    // MARK: - Watchlist

    public func watchlist(memberID: String) async throws -> [WatchlistItem] {
        try await paginate(startPage: 1) { page in
            let html = try await fetcher.html(for: LetterboxdURLs.watchlist(memberID, page: page))
            return (try LetterboxdParser.watchlist(html), try LetterboxdParser.totalPages(in: html))
        }
    }

    // MARK: - Lists

    public func lists(memberID: String) async throws -> [FilmList] {
        let lists = try await paginate(startPage: 1) { page in
            let html = try await fetcher.html(for: LetterboxdURLs.lists(memberID, page: page))
            return (try LetterboxdParser.lists(html), try LetterboxdParser.totalPages(in: html))
        }
        // Optionally enrich a capped number of lists with their films.
        guard maxListFilmFetches > 0 else { return lists }
        var enriched: [FilmList] = []
        for (index, list) in lists.enumerated() {
            guard index < maxListFilmFetches else { enriched.append(list); continue }
            let films = try await listFilms(memberID: memberID, list: list)
            enriched.append(FilmList(id: list.id, name: list.name, description: list.description, ranked: list.ranked, films: films))
        }
        return enriched
    }

    private func listFilms(memberID: String, list: FilmList) async throws -> [Film] {
        // List film pages share the films-grid markup.
        let entries = try await paginate(startPage: 1) { page in
            let path = page <= 1 ? "\(memberID)/list/\(list.id)/" : "\(memberID)/list/\(list.id)/page/\(page)/"
            let url = LetterboxdURLs.base.appending(path: path)
            let html = try await fetcher.html(for: url)
            return (try LetterboxdParser.watchlist(html), try LetterboxdParser.totalPages(in: html))
        }
        return entries.map(\.film)
    }

    // MARK: - Pagination driver

    /// Walk pages sequentially with the politeness delay (enforced by the fetcher)
    /// until `totalPages` is reached or a page yields no items, capped at `maxPages`.
    private func paginate<T>(
        startPage: Int,
        fetch: (Int) async throws -> ([T], Int)
    ) async throws -> [T] {
        var all: [T] = []
        var page = max(1, startPage)
        var total = page
        let limit = page + maxPages - 1
        while page <= total && page <= limit {
            let items: [T]
            let reportedTotal: Int
            do {
                (items, reportedTotal) = try await fetch(page)
            } catch {
                // Cloudflare commonly serves page 1 from edge cache but challenges
                // (403s) deeper pages for unauthenticated clients. Treat a failure
                // on any page after the first as "end of data" and keep what we
                // have, rather than failing the whole sync.
                if page == startPage { throw error }
                break
            }
            if page == startPage { total = max(reportedTotal, startPage) }
            if items.isEmpty { break }
            all.append(contentsOf: items)
            page += 1
        }
        return all
    }
}
