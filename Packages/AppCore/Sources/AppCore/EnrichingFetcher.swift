import FilmEnrichment
import LocalStore
import MiseCore

/// A `LetterboxdFetching` decorator that enriches the `Film`s in fetched results
/// with TMDB metadata (genres, runtime, tmdbID, posterURL) before returning them.
///
/// Wraps any `LetterboxdFetching` (typically the scraper) plus an *optional*
/// `FilmEnricher`. When the enricher is `nil` (e.g. no TMDB key configured), every
/// call is a pure pass-through and films are returned unchanged — graceful
/// degradation. `member(username:)` and `statistics(memberID:)` carry no films and
/// are always passed straight through.
public struct EnrichingFetcher: LetterboxdFetching {
    private let base: any LetterboxdFetching
    private let enricher: FilmEnricher?

    /// - Parameters:
    ///   - base: The underlying fetcher whose results will be enriched.
    ///   - enricher: The TMDB enricher, or `nil` to pass films through unchanged.
    public init(base: any LetterboxdFetching, enricher: FilmEnricher?) {
        self.base = base
        self.enricher = enricher
    }

    // MARK: - Pass-through (no films to enrich)

    public func member(username: String) async throws -> MemberSummary {
        try await base.member(username: username)
    }

    public func statistics(memberID: String) async throws -> MemberStatistics {
        try await base.statistics(memberID: memberID)
    }

    // MARK: - Enriched results

    public func logEntries(memberID: String, perPage: Int, cursor: String?) async throws -> [DiaryEntry] {
        let entries = try await base.logEntries(memberID: memberID, perPage: perPage, cursor: cursor)
        guard let enricher else { return entries }
        let enrichedFilms = await enricher.enrich(entries.map(\.film))
        return zip(entries, enrichedFilms).map { entry, film in
            entry.replacingFilm(film)
        }
    }

    public func watchlist(memberID: String) async throws -> [WatchlistItem] {
        let items = try await base.watchlist(memberID: memberID)
        guard let enricher else { return items }
        let enrichedFilms = await enricher.enrich(items.map(\.film))
        return zip(items, enrichedFilms).map { item, film in
            WatchlistItem(film: film, addedDate: item.addedDate)
        }
    }

    public func lists(memberID: String) async throws -> [FilmList] {
        let lists = try await base.lists(memberID: memberID)
        guard let enricher else { return lists }
        var out: [FilmList] = []
        out.reserveCapacity(lists.count)
        for list in lists {
            let enrichedFilms = await enricher.enrich(list.films)
            out.append(
                FilmList(
                    id: list.id,
                    name: list.name,
                    description: list.description,
                    ranked: list.ranked,
                    films: enrichedFilms
                )
            )
        }
        return out
    }
}

private extension DiaryEntry {
    /// A copy of this entry with its film swapped, preserving all other fields.
    func replacingFilm(_ film: Film) -> DiaryEntry {
        DiaryEntry(
            id: id,
            film: film,
            watchedDate: watchedDate,
            loggedDate: loggedDate,
            rating: rating,
            isRewatch: isRewatch,
            isLiked: isLiked,
            review: review,
            tags: tags
        )
    }
}
