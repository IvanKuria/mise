import Foundation
import Testing
import MiseCore
@testable import FilmQuery

@Suite("FilmFilter — combined (AND)")
struct CombinedFilterTests {
    let entries: [DiaryEntry] = {
        let f = Fixtures.self
        return [
            f.entry(id: "e1", film: f.film(id: "m1", name: "Alien", year: 1979, runtime: 117, genres: ["Horror", "Sci-Fi"]), watched: f.date(1), rating: f.rating(8), isLiked: true),
            f.entry(id: "e2", film: f.film(id: "m2", name: "Aliens", year: 1986, runtime: 137, genres: ["Action", "Sci-Fi"]), watched: f.date(2), rating: f.rating(9), isRewatch: true, isLiked: true, review: "bigger"),
            f.entry(id: "e3", film: f.film(id: "m3", name: "Avatar", year: 2009, runtime: 162, genres: ["Action", "Sci-Fi"]), watched: f.date(3), rating: f.rating(6)),
            f.entry(id: "e4", film: f.film(id: "m4", name: "Arrival", year: 2016, runtime: 116, genres: ["Sci-Fi", "Drama"]), watched: f.date(4), rating: f.rating(9), isLiked: true, review: "wow"),
        ]
    }()

    func ids(_ filter: FilmFilter) -> Set<String> {
        Set(FilmQuery.filter(filter, in: entries).map(\.id))
    }

    @Test("all dimensions combine with AND")
    func combinedAnd() {
        var filter = FilmFilter()
        filter.genres = ["Sci-Fi"]
        filter.ratingRange = Fixtures.rating(9)...Fixtures.rating(10)
        filter.isLiked = true
        // Sci-Fi AND rating >= 4.5 stars AND liked -> e2 (9, liked), e4 (9, liked).
        #expect(ids(filter) == ["e2", "e4"])
    }

    @Test("adding a dimension never widens the result")
    func narrowing() {
        let base = FilmFilter(genres: ["Sci-Fi"])
        let baseIDs = ids(base)
        var narrowed = base
        narrowed.hasReview = true
        #expect(ids(narrowed).isSubset(of: baseIDs))
        #expect(ids(narrowed) == ["e2", "e4"])
    }

    @Test("contradictory constraints yield empty")
    func contradictory() {
        var filter = FilmFilter(genres: ["Horror"]) // only e1
        filter.isRewatch = true // e1 is not a rewatch
        #expect(ids(filter).isEmpty)
    }

    @Test("free text combined with year range")
    func freeTextPlusYear() {
        var filter = FilmFilter(freeText: "alien") // e1 Alien, e2 Aliens
        filter.yearRange = 1980...1990
        #expect(ids(filter) == ["e2"]) // Aliens (1986)
    }
}
