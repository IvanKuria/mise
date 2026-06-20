import Foundation
import MiseCore
import TMDBKit

/// Resolves Letterboxd films to TMDB and fills in the metadata Letterboxd does
/// not give us (genres, runtime, countries, poster, tmdb id), preserving every
/// field already on the film.
public actor FilmEnricher {
    /// The TMDB image size used for poster URLs.
    public static let posterSize = "w500"

    private let provider: any MovieMetadataProviding
    /// Resolved TMDB ids keyed by a normalized (title, year). A cached `nil` means
    /// "looked up, no match" so we don't re-search a film that has no TMDB entry.
    private var resolutionCache: [CacheKey: Int?] = [:]

    public init(provider: any MovieMetadataProviding) {
        self.provider = provider
    }

    /// Enriches a batch of films, preserving input order.
    public func enrich(_ films: [Film]) async -> [Film] {
        var out: [Film] = []
        out.reserveCapacity(films.count)
        for film in films {
            out.append(await enrich(film))
        }
        return out
    }

    /// Fills missing TMDB-sourced metadata on `film`. Returns the film unchanged
    /// when no TMDB match can be found.
    public func enrich(_ film: Film) async -> Film {
        // Already linked to TMDB: just fetch and fill.
        if let tmdbID = film.tmdbID {
            guard let movie = try? await provider.movie(tmdbID: tmdbID) else { return film }
            return film.filling(from: movie, posterSize: Self.posterSize)
        }

        guard let tmdbID = await resolve(film) else { return film }
        guard let movie = try? await provider.movie(tmdbID: tmdbID) else { return film }
        return film.filling(from: movie, posterSize: Self.posterSize)
    }

    /// Resolves a film to a TMDB id via search + best-match, memoized by (title, year).
    private func resolve(_ film: Film) async -> Int? {
        let key = CacheKey(title: film.name, year: film.releaseYear)
        if let cached = resolutionCache[key] { return cached }

        let results = (try? await provider.search(title: film.name, year: film.releaseYear)) ?? []
        let match = Self.bestMatch(in: results, year: film.releaseYear)
        let id = match?.id
        resolutionCache[key] = .some(id)
        return id
    }

    /// Picks the best search result: an exact release-year match when the year is
    /// known and present, otherwise the first result. `nil` when there are none.
    static func bestMatch(in results: [TMDBSearchResult], year: Int?) -> TMDBSearchResult? {
        guard !results.isEmpty else { return nil }
        if let year, let exact = results.first(where: { $0.releaseYear == year }) {
            return exact
        }
        return results.first
    }
}

/// A normalized lookup key so " PARASITE " (2019) and "Parasite" (2019) collapse.
private struct CacheKey: Hashable {
    let title: String
    let year: Int?

    init(title: String, year: Int?) {
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        self.year = year
    }
}

private extension Film {
    /// Returns a copy with missing metadata filled from a TMDB movie. Existing
    /// Letterboxd-sourced fields (id, name, year, rating, urls, people) are kept.
    func filling(from movie: TMDBMovie, posterSize: String) -> Film {
        Film(
            id: id,
            name: name,
            releaseYear: releaseYear,
            runtimeMinutes: runtimeMinutes ?? movie.runtime,
            genres: genres.isEmpty ? movie.genres.map(Genre.fromTMDBName) : genres,
            directors: directors,
            cast: cast,
            countries: countries,
            languages: languages,
            tmdbID: tmdbID ?? movie.id,
            posterURL: posterURL ?? Film.posterURL(path: movie.posterPath, size: posterSize),
            letterboxdAverageRating: letterboxdAverageRating,
            letterboxdURL: letterboxdURL
        )
    }

    /// Builds an image URL: https://image.tmdb.org/t/p/{size}{path}. `nil` for an
    /// empty or absent path.
    static func posterURL(path: String?, size: String) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/\(size)\(path)")
    }
}

private extension Genre {
    /// Synthesizes a stable Genre from a TMDB genre name (id = lowercased name).
    static func fromTMDBName(_ name: String) -> Genre {
        Genre(id: name.lowercased(), name: name)
    }
}
