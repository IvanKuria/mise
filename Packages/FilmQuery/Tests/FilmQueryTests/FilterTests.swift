import Foundation
import Testing
import MiseCore
@testable import FilmQuery

@Suite("FilmFilter — single dimensions")
struct FilterTests {
    // A small, varied corpus.
    let entries: [DiaryEntry] = {
        let f = Fixtures.self
        return [
            f.entry(
                id: "e1",
                film: f.film(id: "m1", name: "Amélie", year: 2001, runtime: 122, genres: ["Romance", "Comedy"]),
                watched: f.date(10), rating: f.rating(9), isLiked: true, review: "lovely"
            ),
            f.entry(
                id: "e2",
                film: f.film(id: "m2", name: "Alien", year: 1979, runtime: 117, genres: ["Horror", "Sci-Fi"]),
                watched: f.date(20), rating: f.rating(8), isRewatch: true
            ),
            f.entry(
                id: "e3",
                film: f.film(id: "m3", name: "Jaws", year: 1975, runtime: 124, genres: ["Thriller", "Horror"]),
                watched: f.date(30), rating: f.rating(7)
            ),
            f.entry(
                id: "e4",
                film: f.film(id: "m4", name: "Up", year: 2009, runtime: 96, genres: ["Animation", "Comedy"]),
                watched: f.date(40), rating: f.rating(10), isLiked: true, review: "tears"
            ),
            f.entry(
                id: "e5",
                film: f.film(id: "m5", name: "Untitled", year: nil, runtime: nil, genres: []),
                watched: nil, rating: nil
            ),
        ]
    }()

    func ids(_ filter: FilmFilter) -> Set<String> {
        Set(FilmQuery.filter(filter, in: entries).map(\.id))
    }

    @Test("empty filter matches everything")
    func emptyMatchesAll() {
        #expect(FilmFilter.all.isEmpty)
        #expect(FilmFilter().isEmpty)
        #expect(ids(.all) == Set(entries.map(\.id)))
    }

    @Test("rating range is inclusive and excludes ratingless entries")
    func ratingRange() {
        let filter = FilmFilter(ratingRange: Fixtures.rating(8)...Fixtures.rating(9))
        #expect(ids(filter) == ["e1", "e2"])
        // e5 has no rating -> excluded even by a wide range.
        let wide = FilmFilter(ratingRange: Fixtures.rating(1)...Fixtures.rating(10))
        #expect(ids(wide) == ["e1", "e2", "e3", "e4"])
    }

    @Test("withRatingHalfStars convenience builder")
    func ratingHalfStarsBuilder() {
        let filter = FilmFilter.all.withRatingHalfStars(min: 10, max: 10)
        #expect(ids(filter) == ["e4"])
        // Out-of-range bounds leave the filter unchanged (still .all).
        #expect(FilmFilter.all.withRatingHalfStars(min: 0, max: 11).isEmpty)
        // min > max leaves it unchanged.
        #expect(FilmFilter.all.withRatingHalfStars(min: 8, max: 2).isEmpty)
    }

    @Test("genres match-any")
    func genresMatchAny() {
        let filter = FilmFilter(genres: ["Horror"])
        #expect(ids(filter) == ["e2", "e3"])
        let multi = FilmFilter(genres: ["Comedy", "Animation"])
        #expect(ids(multi) == ["e1", "e4"])
        // Empty genre set imposes no constraint.
        #expect(ids(FilmFilter(genres: [])) == Set(entries.map(\.id)))
    }

    @Test("decades")
    func decades() {
        let filter = FilmFilter(decades: [1970])
        #expect(ids(filter) == ["e2", "e3"])
        let multi = FilmFilter(decades: [2000])
        #expect(ids(multi) == ["e1", "e4"])
        // e5 has no decade -> excluded.
    }

    @Test("year range inclusive, excludes yearless")
    func yearRange() {
        let filter = FilmFilter(yearRange: 1975...2001)
        #expect(ids(filter) == ["e1", "e2", "e3"])
    }

    @Test("isRewatch flag")
    func rewatch() {
        #expect(ids(FilmFilter(isRewatch: true)) == ["e2"])
        #expect(ids(FilmFilter(isRewatch: false)) == ["e1", "e3", "e4", "e5"])
    }

    @Test("isLiked flag")
    func liked() {
        #expect(ids(FilmFilter(isLiked: true)) == ["e1", "e4"])
    }

    @Test("hasReview flag")
    func hasReview() {
        #expect(ids(FilmFilter(hasReview: true)) == ["e1", "e4"])
        #expect(ids(FilmFilter(hasReview: false)) == ["e2", "e3", "e5"])
    }

    @Test("runtime range inclusive, excludes runtimeless")
    func runtimeRange() {
        let filter = FilmFilter(runtimeRange: 117...124)
        #expect(ids(filter) == ["e1", "e2", "e3"])
        // e4 (96) and e5 (nil) excluded.
    }

    @Test("watched date range inclusive, excludes dateless")
    func watchedDateRange() {
        let filter = FilmFilter(watchedDateRange: Fixtures.date(20)...Fixtures.date(30))
        #expect(ids(filter) == ["e2", "e3"])
        // e5 has no watched date.
    }

    @Test("free text is case-insensitive substring")
    func freeTextCaseInsensitive() {
        #expect(ids(FilmFilter(freeText: "ali")) == ["e2"]) // Alien
        #expect(ids(FilmFilter(freeText: "UP")) == ["e4"])
    }

    @Test("free text is diacritic-insensitive both ways")
    func freeTextDiacriticInsensitive() {
        // Query without accent matches accented name.
        #expect(ids(FilmFilter(freeText: "amelie")) == ["e1"]) // Amélie
        // Query with accent matches too.
        #expect(ids(FilmFilter(freeText: "Amélie")) == ["e1"])
    }

    @Test("free text whitespace-only is treated as no constraint")
    func freeTextBlank() {
        #expect(FilmFilter(freeText: "   ").isEmpty)
        #expect(ids(FilmFilter(freeText: "   ")) == Set(entries.map(\.id)))
    }
}
