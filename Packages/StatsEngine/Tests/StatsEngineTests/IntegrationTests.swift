import Foundation
import Testing
import MiseCore
@testable import StatsEngine

@Suite("Integration")
struct IntegrationTests {
    @Test("end-to-end over a realistic mixed history")
    func endToEnd() {
        let drama = Fixtures.genre("Drama")
        let nolan = Fixtures.person("Christopher Nolan")
        let star = Fixtures.person("Lead Actor")

        let dunkirk = Fixtures.film(
            id: "dunkirk", name: "Dunkirk", year: 2017, runtime: 106,
            genres: [drama], directors: [nolan], cast: [star],
            countries: ["UK"], languages: ["English"], lbAvg: 3.9
        )
        let interstellar = Fixtures.film(
            id: "interstellar", name: "Interstellar", year: 2014, runtime: 169,
            genres: [drama], directors: [nolan], cast: [star],
            countries: ["USA"], languages: ["English"], lbAvg: 4.1
        )

        let history = Fixtures.history([
            Fixtures.entry(id: "1", film: dunkirk, watched: "2024-01-01",
                           rating: Fixtures.rating(4.5), isLiked: true, review: "tense"),
            Fixtures.entry(id: "2", film: interstellar, watched: "2024-01-02",
                           rating: Fixtures.rating(5.0), isLiked: true),
            Fixtures.entry(id: "3", film: interstellar, watched: "2024-06-10",
                           rating: Fixtures.rating(4.0), isRewatch: true),
        ])

        let stats = StatsEngine.compute(history)

        #expect(stats.totalLogged == 3)
        #expect(stats.distinctFilmCount == 2)
        #expect(stats.rewatchCount == 1)
        #expect(stats.likedCount == 2)
        #expect(stats.reviewCount == 1)
        #expect(stats.ratingsHistogram == [9: 1, 10: 1, 8: 1])
        #expect(stats.totalRuntimeMinutes == 106 + 169 + 169)
        #expect(stats.runtimeMinutesPerYear[2024] == 106 + 169 + 169)
        #expect(stats.genreBreakdown["Drama"]?.count == 3)
        #expect(stats.topDirectors.first?.name == "Christopher Nolan")
        #expect(stats.topDirectors.first?.count == 3)
        #expect(stats.topCast.first?.name == "Lead Actor") // 3 appearances >= 2
        #expect(stats.filmsPerYear[2024] == 3)
        #expect(stats.longestStreakDays == 2) // Jan 1-2
        #expect(stats.currentStreakDays == 1) // ends Jun 10, isolated
        #expect(stats.contrarianScore != nil)
        #expect(!stats.hottestTakes.isEmpty)
    }
}
