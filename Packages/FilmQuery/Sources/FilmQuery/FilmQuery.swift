import Foundation
import MiseCore

/// The pure, deterministic faceted filter/sort engine that powers the
/// power-browser. No I/O, no UI, no shared state.
public enum FilmQuery {
    /// Filters `entries` by `filter`, then sorts the survivors by `sort`.
    /// Deterministic for a given input regardless of input order.
    public static func apply(
        _ filter: FilmFilter,
        sort: FilmSort,
        to entries: [DiaryEntry]
    ) -> [DiaryEntry] {
        let filtered = filter.isEmpty ? entries : entries.filter(filter.matches)
        return filtered.sorted(by: sort.areInIncreasingOrder)
    }

    /// Filters `entries` without sorting (preserving input order).
    public static func filter(_ filter: FilmFilter, in entries: [DiaryEntry]) -> [DiaryEntry] {
        filter.isEmpty ? entries : entries.filter(filter.matches)
    }

    /// Sorts `entries` by `sort` (no filtering).
    public static func sort(_ entries: [DiaryEntry], by sort: FilmSort) -> [DiaryEntry] {
        entries.sorted(by: sort.areInIncreasingOrder)
    }

    /// Computes the available facets present in `entries`, with per-value counts,
    /// to drive UI filter controls.
    public static func availableFacets(in entries: [DiaryEntry]) -> Facets {
        guard !entries.isEmpty else { return .empty }

        var genreCounts: [String: Int] = [:]
        var decadeCounts: [Int: Int] = [:]
        var minYear: Int?
        var maxYear: Int?
        var minRuntime: Int?
        var maxRuntime: Int?

        for entry in entries {
            let film = entry.film

            // Genres: count each distinct genre once per entry.
            for name in Set(film.genres.map(\.name)) {
                genreCounts[name, default: 0] += 1
            }

            if let decade = film.decade {
                decadeCounts[decade, default: 0] += 1
            }

            if let year = film.releaseYear {
                minYear = min(minYear ?? year, year)
                maxYear = max(maxYear ?? year, year)
            }

            if let runtime = film.runtimeMinutes {
                minRuntime = min(minRuntime ?? runtime, runtime)
                maxRuntime = max(maxRuntime ?? runtime, runtime)
            }
        }

        let genres = genreCounts
            .map { Facets.Count(value: $0.key, count: $0.value) }
            .sorted { $0.value < $1.value }
        let decades = decadeCounts
            .map { Facets.Count(value: $0.key, count: $0.value) }
            .sorted { $0.value < $1.value }

        let yearRange = minYear.flatMap { lo in maxYear.map { lo...$0 } }
        let runtimeRange = minRuntime.flatMap { lo in maxRuntime.map { lo...$0 } }

        return Facets(genres: genres, decades: decades, yearRange: yearRange, runtimeRange: runtimeRange)
    }
}

// MARK: - [Film] helpers

extension FilmQuery {
    /// Wraps bare films as ratingless, dateless diary entries so the same filter
    /// engine can drive a `[Film]` browser (e.g. a watchlist). The synthesized
    /// entry id is the film id; rating/date/flag dimensions never match.
    public static func entries(from films: [Film]) -> [DiaryEntry] {
        films.map { DiaryEntry(id: $0.id, film: $0) }
    }

    /// Filters and sorts a list of bare films via the diary engine, returning
    /// films. Rating, watched-date, like, rewatch, and review dimensions of the
    /// filter cannot match a bare film and will exclude everything if set.
    public static func apply(
        _ filter: FilmFilter,
        sort: FilmSort,
        to films: [Film]
    ) -> [Film] {
        apply(filter, sort: sort, to: entries(from: films)).map(\.film)
    }

    /// Computes facets for a list of bare films.
    public static func availableFacets(in films: [Film]) -> Facets {
        availableFacets(in: entries(from: films))
    }
}
