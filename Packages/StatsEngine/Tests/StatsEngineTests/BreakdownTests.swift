import Foundation
import Testing
import MiseCore
@testable import StatsEngine

@Suite("Breakdowns")
struct BreakdownTests {
    @Test("genre breakdown counts every appearance and averages ratings")
    func genre() {
        let drama = Fixtures.genre("Drama")
        let crime = Fixtures.genre("Crime")
        let f1 = Fixtures.film(id: "f1", genres: [drama, crime])
        let f2 = Fixtures.film(id: "f2", genres: [drama])
        let history = Fixtures.history([
            Fixtures.entry(id: "1", film: f1, rating: Fixtures.rating(4.0)),
            Fixtures.entry(id: "2", film: f2, rating: Fixtures.rating(3.0)),
            Fixtures.entry(id: "3", film: f2), // unrated, still counts toward count
        ])
        let stats = StatsEngine.compute(history)
        #expect(stats.genreBreakdown["Drama"]?.count == 3)
        #expect(stats.genreBreakdown["Drama"]?.averageRating == 3.5) // (4 + 3) / 2
        #expect(stats.genreBreakdown["Crime"]?.count == 1)
        #expect(stats.genreBreakdown["Crime"]?.averageRating == 4.0)
    }

    @Test("decade breakdown buckets by release decade, ignores unknown year")
    func decade() {
        let a = Fixtures.film(id: "a", year: 1994)
        let b = Fixtures.film(id: "b", year: 1999)
        let c = Fixtures.film(id: "c", year: 2001)
        let d = Fixtures.film(id: "d", year: nil)
        let history = Fixtures.history([
            Fixtures.entry(id: "1", film: a, rating: Fixtures.rating(5.0)),
            Fixtures.entry(id: "2", film: b, rating: Fixtures.rating(4.0)),
            Fixtures.entry(id: "3", film: c),
            Fixtures.entry(id: "4", film: d, rating: Fixtures.rating(1.0)),
        ])
        let stats = StatsEngine.compute(history)
        #expect(stats.decadeBreakdown[1990]?.count == 2)
        #expect(stats.decadeBreakdown[1990]?.averageRating == 4.5)
        #expect(stats.decadeBreakdown[2000]?.count == 1)
        #expect(stats.decadeBreakdown[2000]?.averageRating == nil) // unrated only
        #expect(stats.decadeBreakdown.count == 2) // unknown year contributes no bucket
    }

    @Test("country and language breakdowns")
    func countryLanguage() {
        let a = Fixtures.film(id: "a", countries: ["USA"], languages: ["English"])
        let b = Fixtures.film(id: "b", countries: ["France"], languages: ["French", "English"])
        let history = Fixtures.history([
            Fixtures.entry(id: "1", film: a, rating: Fixtures.rating(4.0)),
            Fixtures.entry(id: "2", film: b, rating: Fixtures.rating(2.0)),
        ])
        let stats = StatsEngine.compute(history)
        #expect(stats.countryBreakdown["USA"]?.count == 1)
        #expect(stats.countryBreakdown["France"]?.count == 1)
        #expect(stats.languageBreakdown["English"]?.count == 2)
        #expect(stats.languageBreakdown["English"]?.averageRating == 3.0) // (4 + 2)/2
        #expect(stats.languageBreakdown["French"]?.count == 1)
    }
}
