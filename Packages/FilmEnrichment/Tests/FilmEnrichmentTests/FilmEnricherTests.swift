import Foundation
import Testing
import MiseCore
import TMDBKit
@testable import FilmEnrichment

@Suite("FilmEnricher")
struct FilmEnricherTests {

    // MARK: - Helpers

    private func movie(
        id: Int,
        title: String = "Parasite",
        runtime: Int? = 133,
        releaseDate: String? = "2019-05-30",
        genres: [String] = ["Comedy", "Thriller", "Drama"],
        poster: String? = "/poster.jpg"
    ) -> TMDBMovie {
        TMDBMovie(id: id, title: title, posterPath: poster, runtime: runtime, releaseDate: releaseDate, genres: genres)
    }

    // MARK: - search + best match

    @Test("enriches via search and fills genres, runtime, tmdbID, poster")
    func enrichesFromSearch() async throws {
        let provider = MockMetadataProvider(
            searchResults: ["parasite": [TMDBSearchResult(id: 496243, title: "Parasite", releaseYear: 2019, posterPath: "/p.jpg")]],
            movies: [496243: movie(id: 496243)]
        )
        let enricher = FilmEnricher(provider: provider)
        let film = Film(id: "lb1", name: "Parasite", releaseYear: 2019)

        let result = await enricher.enrich(film)

        #expect(result.tmdbID == 496243)
        #expect(result.runtimeMinutes == 133)
        #expect(result.genres.map(\.name) == ["Comedy", "Thriller", "Drama"])
        #expect(result.genres.first?.id == "comedy")
        #expect(result.posterURL != nil)
    }

    @Test("prefers an exact release-year match over earlier/later results")
    func prefersExactYearMatch() async throws {
        let provider = MockMetadataProvider(
            searchResults: ["parasite": [
                TMDBSearchResult(id: 11, title: "Parasite", releaseYear: 1982, posterPath: nil),
                TMDBSearchResult(id: 22, title: "Parasite", releaseYear: 2019, posterPath: nil),
                TMDBSearchResult(id: 33, title: "Parasite", releaseYear: 2024, posterPath: nil),
            ]],
            movies: [
                11: movie(id: 11, releaseDate: "1982-01-01"),
                22: movie(id: 22, releaseDate: "2019-05-30"),
                33: movie(id: 33, releaseDate: "2024-01-01"),
            ]
        )
        let enricher = FilmEnricher(provider: provider)
        let film = Film(id: "lb1", name: "Parasite", releaseYear: 2019)

        let result = await enricher.enrich(film)

        #expect(result.tmdbID == 22)
    }

    @Test("falls back to the first result when no year matches")
    func fallsBackToFirstWhenNoYearMatch() async throws {
        let provider = MockMetadataProvider(
            searchResults: ["parasite": [
                TMDBSearchResult(id: 11, title: "Parasite", releaseYear: 1982, posterPath: nil),
                TMDBSearchResult(id: 33, title: "Parasite", releaseYear: 2024, posterPath: nil),
            ]],
            movies: [11: movie(id: 11), 33: movie(id: 33)]
        )
        let enricher = FilmEnricher(provider: provider)
        let film = Film(id: "lb1", name: "Parasite", releaseYear: 2019)

        let result = await enricher.enrich(film)

        #expect(result.tmdbID == 11)
    }

    @Test("uses the first result when year is unknown")
    func usesFirstWhenYearUnknown() async throws {
        let provider = MockMetadataProvider(
            searchResults: ["parasite": [
                TMDBSearchResult(id: 11, title: "Parasite", releaseYear: 1982, posterPath: nil),
                TMDBSearchResult(id: 22, title: "Parasite", releaseYear: 2019, posterPath: nil),
            ]],
            movies: [11: movie(id: 11), 22: movie(id: 22)]
        )
        let enricher = FilmEnricher(provider: provider)
        let film = Film(id: "lb1", name: "Parasite", releaseYear: nil)

        let result = await enricher.enrich(film)

        #expect(result.tmdbID == 11)
    }

    // MARK: - already has tmdbID

    @Test("when film already has tmdbID, fetches movie and skips search")
    func skipsSearchWhenTMDBIDPresent() async throws {
        let provider = MockMetadataProvider(movies: [496243: movie(id: 496243)])
        let enricher = FilmEnricher(provider: provider)
        let film = Film(id: "lb1", name: "Parasite", releaseYear: 2019, tmdbID: 496243)

        let result = await enricher.enrich(film)

        #expect(result.tmdbID == 496243)
        #expect(result.runtimeMinutes == 133)
        #expect(await provider.searchCallCount == 0)
        #expect(await provider.movieCallCount == 1)
    }

    // MARK: - no results

    @Test("leaves the film unchanged when search returns nothing")
    func noResultsLeavesUnchanged() async throws {
        let provider = MockMetadataProvider(searchResults: [:])
        let enricher = FilmEnricher(provider: provider)
        let film = Film(id: "lb1", name: "Unknown Film", releaseYear: 2000, letterboxdAverageRating: 4.1)

        let result = await enricher.enrich(film)

        #expect(result == film)
        #expect(await provider.movieCallCount == 0)
    }

    @Test("preserves existing Film fields, only filling metadata")
    func preservesExistingFields() async throws {
        let provider = MockMetadataProvider(
            searchResults: ["parasite": [TMDBSearchResult(id: 496243, title: "Parasite", releaseYear: 2019, posterPath: nil)]],
            movies: [496243: movie(id: 496243)]
        )
        let enricher = FilmEnricher(provider: provider)
        let url = URL(string: "https://letterboxd.com/film/parasite-2019/")!
        let film = Film(
            id: "lb1",
            name: "Parasite",
            releaseYear: 2019,
            directors: [Person(id: "p1", name: "Bong Joon-ho")],
            letterboxdAverageRating: 4.6,
            letterboxdURL: url
        )

        let result = await enricher.enrich(film)

        #expect(result.id == "lb1")
        #expect(result.name == "Parasite")
        #expect(result.releaseYear == 2019)
        #expect(result.directors.map(\.name) == ["Bong Joon-ho"])
        #expect(result.letterboxdAverageRating == 4.6)
        #expect(result.letterboxdURL == url)
        #expect(result.tmdbID == 496243)
    }

    // MARK: - caching

    @Test("caches resolution so repeated (title, year) does not re-search")
    func cachesResolution() async throws {
        let provider = MockMetadataProvider(
            searchResults: ["parasite": [TMDBSearchResult(id: 496243, title: "Parasite", releaseYear: 2019, posterPath: nil)]],
            movies: [496243: movie(id: 496243)]
        )
        let enricher = FilmEnricher(provider: provider)
        let film1 = Film(id: "lb1", name: "Parasite", releaseYear: 2019)
        let film2 = Film(id: "lb2", name: "  PARASITE ", releaseYear: 2019)

        let r1 = await enricher.enrich(film1)
        let r2 = await enricher.enrich(film2)

        #expect(r1.tmdbID == 496243)
        #expect(r2.tmdbID == 496243)
        #expect(await provider.searchCallCount == 1)
    }

    // MARK: - batch

    @Test("batch enrich processes every film")
    func batchEnrich() async throws {
        let provider = MockMetadataProvider(
            searchResults: [
                "parasite": [TMDBSearchResult(id: 1, title: "Parasite", releaseYear: 2019, posterPath: nil)],
                "burning": [TMDBSearchResult(id: 2, title: "Burning", releaseYear: 2018, posterPath: nil)],
            ],
            movies: [
                1: movie(id: 1, title: "Parasite", genres: ["Drama"]),
                2: movie(id: 2, title: "Burning", genres: ["Mystery"]),
            ]
        )
        let enricher = FilmEnricher(provider: provider)
        let films = [
            Film(id: "lb1", name: "Parasite", releaseYear: 2019),
            Film(id: "lb2", name: "Burning", releaseYear: 2018),
        ]

        let results = await enricher.enrich(films)

        #expect(results.count == 2)
        #expect(results[0].tmdbID == 1)
        #expect(results[1].tmdbID == 2)
        #expect(results.map { $0.id } == ["lb1", "lb2"])
    }
}
