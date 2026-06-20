import Foundation
import Testing
import MiseCore
@testable import FilmQuery

@Suite("Facets + apply + film helpers")
struct FacetsAndApplyTests {
    let f = Fixtures.self

    @Test("availableFacets extracts distinct genres with counts")
    func genreFacets() {
        let entries = [
            f.entry(id: "e1", film: f.film(id: "1", name: "A", year: 1979, runtime: 117, genres: ["Horror", "Sci-Fi"])),
            f.entry(id: "e2", film: f.film(id: "2", name: "B", year: 1986, runtime: 137, genres: ["Sci-Fi", "Action"])),
            f.entry(id: "e3", film: f.film(id: "3", name: "C", year: 2009, runtime: 96, genres: ["Sci-Fi"])),
        ]
        let facets = FilmQuery.availableFacets(in: entries)
        let genreMap = Dictionary(uniqueKeysWithValues: facets.genres.map { ($0.value, $0.count) })
        #expect(genreMap == ["Sci-Fi": 3, "Horror": 1, "Action": 1])
        // Sorted ascending by name.
        #expect(facets.genres.map(\.value) == ["Action", "Horror", "Sci-Fi"])
    }

    @Test("genre counted once per entry even if duplicated on a film")
    func genreDedupPerEntry() {
        let dupFilm = Film(id: "1", name: "Dup", genres: [Genre(id: "h", name: "Horror"), Genre(id: "h2", name: "Horror")])
        let entries = [f.entry(id: "e1", film: dupFilm)]
        let facets = FilmQuery.availableFacets(in: entries)
        #expect(facets.genres == [Facets.Count(value: "Horror", count: 1)])
    }

    @Test("decade facets with counts, sorted ascending")
    func decadeFacets() {
        let entries = [
            f.entry(id: "e1", film: f.film(id: "1", name: "A", year: 1979)),
            f.entry(id: "e2", film: f.film(id: "2", name: "B", year: 1975)),
            f.entry(id: "e3", film: f.film(id: "3", name: "C", year: 2009)),
            f.entry(id: "e4", film: f.film(id: "4", name: "D", year: nil)),
        ]
        let facets = FilmQuery.availableFacets(in: entries)
        #expect(facets.decades == [
            Facets.Count(value: 1970, count: 2),
            Facets.Count(value: 2000, count: 1),
        ])
    }

    @Test("year and runtime ranges span the present values")
    func ranges() {
        let entries = [
            f.entry(id: "e1", film: f.film(id: "1", name: "A", year: 1979, runtime: 117)),
            f.entry(id: "e2", film: f.film(id: "2", name: "B", year: 2016, runtime: 96)),
            f.entry(id: "e3", film: f.film(id: "3", name: "C", year: nil, runtime: nil)),
        ]
        let facets = FilmQuery.availableFacets(in: entries)
        #expect(facets.yearRange == 1979...2016)
        #expect(facets.runtimeRange == 96...117)
    }

    @Test("empty input yields empty facets and empty apply")
    func emptyInput() {
        let facets = FilmQuery.availableFacets(in: [DiaryEntry]())
        #expect(facets == .empty)
        #expect(facets.genres.isEmpty)
        #expect(facets.decades.isEmpty)
        #expect(facets.yearRange == nil)
        #expect(facets.runtimeRange == nil)
        #expect(FilmQuery.apply(.all, sort: .titleAsc, to: [DiaryEntry]()).isEmpty)
    }

    @Test("facets nil ranges when no years/runtimes present")
    func facetsNoYearRuntime() {
        let entries = [f.entry(id: "e1", film: f.film(id: "1", name: "A"))]
        let facets = FilmQuery.availableFacets(in: entries)
        #expect(facets.yearRange == nil)
        #expect(facets.runtimeRange == nil)
        #expect(facets.decades.isEmpty)
    }

    @Test("apply filters then sorts in one pass")
    func applyFilterThenSort() {
        let entries = [
            f.entry(id: "e1", film: f.film(id: "1", name: "Zodiac", year: 2007, genres: ["Thriller"]), rating: f.rating(9)),
            f.entry(id: "e2", film: f.film(id: "2", name: "Seven", year: 1995, genres: ["Thriller"]), rating: f.rating(10)),
            f.entry(id: "e3", film: f.film(id: "3", name: "Up", year: 2009, genres: ["Animation"]), rating: f.rating(8)),
        ]
        let result = FilmQuery.apply(FilmFilter(genres: ["Thriller"]), sort: .ratingDesc, to: entries)
        #expect(result.map(\.id) == ["e2", "e1"]) // Seven (10) then Zodiac (9)
    }

    // MARK: [Film] helpers

    @Test("apply over [Film] filters and sorts, returns films")
    func applyOverFilms() {
        let films = [
            f.film(id: "1", name: "Brazil", year: 1985, genres: ["Sci-Fi"]),
            f.film(id: "2", name: "Akira", year: 1988, genres: ["Animation", "Sci-Fi"]),
            f.film(id: "3", name: "Heat", year: 1995, genres: ["Crime"]),
        ]
        let result = FilmQuery.apply(FilmFilter(genres: ["Sci-Fi"]), sort: .titleAsc, to: films)
        #expect(result.map(\.id) == ["2", "1"]) // Akira, Brazil
    }

    @Test("rating filter excludes all bare films")
    func ratingFilterOnFilms() {
        let films = [f.film(id: "1", name: "Brazil", year: 1985)]
        let result = FilmQuery.apply(FilmFilter(ratingRange: f.rating(1)...f.rating(10)), sort: .titleAsc, to: films)
        #expect(result.isEmpty)
    }

    @Test("availableFacets over [Film]")
    func facetsOverFilms() {
        let films = [
            f.film(id: "1", name: "A", year: 1985, runtime: 132, genres: ["Sci-Fi"]),
            f.film(id: "2", name: "B", year: 1995, runtime: 170, genres: ["Crime"]),
        ]
        let facets = FilmQuery.availableFacets(in: films)
        #expect(facets.yearRange == 1985...1995)
        #expect(facets.runtimeRange == 132...170)
        #expect(Set(facets.genres.map(\.value)) == ["Sci-Fi", "Crime"])
    }
}
