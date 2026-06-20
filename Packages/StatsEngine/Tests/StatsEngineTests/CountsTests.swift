import Foundation
import Testing
import MiseCore
@testable import StatsEngine

@Suite("Counts")
struct CountsTests {
    @Test("empty history yields zeroed counts")
    func emptyHistory() {
        let stats = StatsEngine.compute(Fixtures.history([]))
        #expect(stats.totalLogged == 0)
        #expect(stats.rewatchCount == 0)
        #expect(stats.likedCount == 0)
        #expect(stats.reviewCount == 0)
        #expect(stats.distinctFilmCount == 0)
        #expect(stats.ratingsHistogram.isEmpty)
    }

    @Test("counts across a small diary")
    func smallDiary() {
        let a = Fixtures.film(id: "a")
        let b = Fixtures.film(id: "b")
        let history = Fixtures.history([
            Fixtures.entry(id: "1", film: a, rating: Fixtures.rating(4.0), isLiked: true, review: "great"),
            Fixtures.entry(id: "2", film: a, isRewatch: true), // rewatch of same film
            Fixtures.entry(id: "3", film: b, rating: Fixtures.rating(2.5)),
            Fixtures.entry(id: "4", film: b, review: ""), // empty review does not count
        ])
        let stats = StatsEngine.compute(history)
        #expect(stats.totalLogged == 4)
        #expect(stats.rewatchCount == 1)
        #expect(stats.likedCount == 1)
        #expect(stats.reviewCount == 1)
        #expect(stats.distinctFilmCount == 2)
    }
}
