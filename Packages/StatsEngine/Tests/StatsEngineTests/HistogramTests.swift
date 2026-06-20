import Foundation
import Testing
import MiseCore
@testable import StatsEngine

@Suite("RatingsHistogram")
struct HistogramTests {
    @Test("histogram keyed by half-stars, counts only rated entries")
    func histogram() {
        let f = Fixtures.film(id: "f")
        let history = Fixtures.history([
            Fixtures.entry(id: "1", film: f, rating: Fixtures.rating(4.0)), // 8
            Fixtures.entry(id: "2", film: f, rating: Fixtures.rating(4.0)), // 8
            Fixtures.entry(id: "3", film: f, rating: Fixtures.rating(4.5)), // 9
            Fixtures.entry(id: "4", film: f),                                // no rating
        ])
        let stats = StatsEngine.compute(history)
        #expect(stats.ratingsHistogram == [8: 2, 9: 1])
    }
}
