import Foundation
import Testing
import MiseCore
@testable import FilmQuery

@Suite("FilmSort")
struct SortTests {
    let f = Fixtures.self

    func ordered(_ sort: FilmSort, _ entries: [DiaryEntry]) -> [String] {
        FilmQuery.sort(entries, by: sort).map(\.id)
    }

    @Test("watchedDate desc and asc, nils last")
    func watchedDate() {
        let entries = [
            f.entry(id: "a", film: f.film(id: "1", name: "A"), watched: f.date(10)),
            f.entry(id: "b", film: f.film(id: "2", name: "B"), watched: f.date(30)),
            f.entry(id: "c", film: f.film(id: "3", name: "C"), watched: f.date(20)),
            f.entry(id: "d", film: f.film(id: "4", name: "D"), watched: nil),
        ]
        #expect(ordered(.watchedDateDesc, entries) == ["b", "c", "a", "d"])
        #expect(ordered(.watchedDateAsc, entries) == ["a", "c", "b", "d"])
    }

    @Test("rating desc and asc, nils last")
    func rating() {
        let entries = [
            f.entry(id: "a", film: f.film(id: "1", name: "A"), rating: f.rating(7)),
            f.entry(id: "b", film: f.film(id: "2", name: "B"), rating: f.rating(10)),
            f.entry(id: "c", film: f.film(id: "3", name: "C"), rating: f.rating(4)),
            f.entry(id: "d", film: f.film(id: "4", name: "D"), rating: nil),
        ]
        #expect(ordered(.ratingDesc, entries) == ["b", "a", "c", "d"])
        #expect(ordered(.ratingAsc, entries) == ["c", "a", "b", "d"])
    }

    @Test("title asc and desc, diacritic/case-insensitive")
    func title() {
        let entries = [
            f.entry(id: "a", film: f.film(id: "1", name: "banana")),
            f.entry(id: "b", film: f.film(id: "2", name: "Apple")),
            f.entry(id: "c", film: f.film(id: "3", name: "Éclair")),
        ]
        // Apple < banana < Éclair (case/diacritic-insensitive).
        #expect(ordered(.titleAsc, entries) == ["b", "a", "c"])
        #expect(ordered(.titleDesc, entries) == ["c", "a", "b"])
    }

    @Test("release year desc and asc, nils last")
    func releaseYear() {
        let entries = [
            f.entry(id: "a", film: f.film(id: "1", name: "A", year: 1999)),
            f.entry(id: "b", film: f.film(id: "2", name: "B", year: 2020)),
            f.entry(id: "c", film: f.film(id: "3", name: "C", year: nil)),
        ]
        #expect(ordered(.releaseYearDesc, entries) == ["b", "a", "c"])
        #expect(ordered(.releaseYearAsc, entries) == ["a", "b", "c"])
    }

    @Test("runtime desc and asc, nils last")
    func runtime() {
        let entries = [
            f.entry(id: "a", film: f.film(id: "1", name: "A", runtime: 90)),
            f.entry(id: "b", film: f.film(id: "2", name: "B", runtime: 200)),
            f.entry(id: "c", film: f.film(id: "3", name: "C", runtime: nil)),
        ]
        #expect(ordered(.runtimeDesc, entries) == ["b", "a", "c"])
        #expect(ordered(.runtimeAsc, entries) == ["a", "b", "c"])
    }

    @Test("tie-break by film name then id is deterministic regardless of input order")
    func tieBreak() {
        // All same rating -> tie-break by name, then id.
        let e1 = f.entry(id: "z", film: f.film(id: "1", name: "Same"), rating: f.rating(8))
        let e2 = f.entry(id: "a", film: f.film(id: "2", name: "Same"), rating: f.rating(8))
        let e3 = f.entry(id: "m", film: f.film(id: "3", name: "Same"), rating: f.rating(8))
        // Names equal -> order by id: a < m < z.
        let expected = ["a", "m", "z"]
        #expect(ordered(.ratingDesc, [e1, e2, e3]) == expected)
        #expect(ordered(.ratingDesc, [e3, e1, e2]) == expected)
        #expect(ordered(.ratingDesc, [e2, e3, e1]) == expected)
    }

    @Test("titleDesc keeps id tie-break ascending for equal titles")
    func titleDescTieBreak() {
        let e1 = f.entry(id: "z", film: f.film(id: "1", name: "Same"))
        let e2 = f.entry(id: "a", film: f.film(id: "2", name: "Same"))
        #expect(ordered(.titleDesc, [e1, e2]) == ["a", "z"])
        #expect(ordered(.titleDesc, [e2, e1]) == ["a", "z"])
    }

    @Test("sort is stable across permutations for every order")
    func deterministicAcrossPermutations() {
        let entries = [
            f.entry(id: "a", film: f.film(id: "1", name: "A", year: 2000, runtime: 100), watched: f.date(5), rating: f.rating(8)),
            f.entry(id: "b", film: f.film(id: "2", name: "B", year: 1990, runtime: 120), watched: f.date(2), rating: f.rating(6)),
            f.entry(id: "c", film: f.film(id: "3", name: "C", year: 2010, runtime: 90), watched: f.date(8), rating: f.rating(10)),
        ]
        let reversed: [DiaryEntry] = entries.reversed()
        for sort in FilmSort.allCases {
            #expect(ordered(sort, entries) == ordered(sort, reversed))
        }
    }
}
