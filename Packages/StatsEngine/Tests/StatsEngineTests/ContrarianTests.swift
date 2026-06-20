import Foundation
import Testing
import MiseCore
@testable import StatsEngine

@Suite("Contrarian")
struct ContrarianTests {
    @Test("score is mean delta over rated films with a known community average")
    func score() {
        let a = Fixtures.film(id: "a", lbAvg: 3.0) // member 4.0 -> +1.0
        let b = Fixtures.film(id: "b", lbAvg: 4.0) // member 2.0 -> -2.0
        let c = Fixtures.film(id: "c", lbAvg: nil) // ignored (no avg)
        let d = Fixtures.film(id: "d", lbAvg: 3.0) // unrated -> ignored
        let history = Fixtures.history([
            Fixtures.entry(id: "1", film: a, rating: Fixtures.rating(4.0)),
            Fixtures.entry(id: "2", film: b, rating: Fixtures.rating(2.0)),
            Fixtures.entry(id: "3", film: c, rating: Fixtures.rating(5.0)),
            Fixtures.entry(id: "4", film: d),
        ])
        let stats = StatsEngine.compute(history)
        // mean of (+1.0, -2.0) = -0.5
        #expect(stats.contrarianScore == -0.5)
    }

    @Test("no eligible films -> nil score, empty takes")
    func noneEligible() {
        let c = Fixtures.film(id: "c", lbAvg: nil)
        let history = Fixtures.history([
            Fixtures.entry(id: "1", film: c, rating: Fixtures.rating(5.0)),
        ])
        let stats = StatsEngine.compute(history)
        #expect(stats.contrarianScore == nil)
        #expect(stats.hottestTakes.isEmpty)
    }

    @Test("hottest takes sorted by absolute delta, limited by options")
    func hottestTakes() {
        let a = Fixtures.film(id: "a", name: "A", lbAvg: 3.0) // +1.0
        let b = Fixtures.film(id: "b", name: "B", lbAvg: 4.5) // -2.0
        let c = Fixtures.film(id: "c", name: "C", lbAvg: 3.5) // -0.5
        let history = Fixtures.history([
            Fixtures.entry(id: "1", film: a, rating: Fixtures.rating(4.0)),
            Fixtures.entry(id: "2", film: b, rating: Fixtures.rating(2.5)),
            Fixtures.entry(id: "3", film: c, rating: Fixtures.rating(3.0)),
        ])
        let stats = StatsEngine.compute(history, options: StatsOptions(maxHottestTakes: 2))
        #expect(stats.hottestTakes.count == 2)
        #expect(stats.hottestTakes[0].filmID == "b") // |−2.0| biggest
        #expect(stats.hottestTakes[0].delta == -2.0)
        #expect(stats.hottestTakes[1].filmID == "a") // |+1.0|
        #expect(stats.hottestTakes[1].delta == 1.0)
    }

    @Test("rewatch with rating counts each rated entry")
    func rewatchCounts() {
        let a = Fixtures.film(id: "a", lbAvg: 3.0)
        let history = Fixtures.history([
            Fixtures.entry(id: "1", film: a, rating: Fixtures.rating(4.0)),            // +1
            Fixtures.entry(id: "2", film: a, rating: Fixtures.rating(2.0), isRewatch: true), // -1
        ])
        let stats = StatsEngine.compute(history)
        #expect(stats.contrarianScore == 0.0) // mean(+1, -1)
        #expect(stats.hottestTakes.count == 2)
    }
}
