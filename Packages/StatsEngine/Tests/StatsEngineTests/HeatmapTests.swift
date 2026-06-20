import Foundation
import Testing
import MiseCore
@testable import StatsEngine

@Suite("Heatmap")
struct HeatmapTests {
    @Test("heatmap counts watches per calendar day, ignores no-date entries")
    func heatmapDays() {
        let f = Fixtures.film(id: "f")
        let history = Fixtures.history([
            Fixtures.entry(id: "1", film: f, watched: "2024-03-01"),
            Fixtures.entry(id: "2", film: f, watched: "2024-03-01"),
            Fixtures.entry(id: "3", film: f, watched: "2024-03-02"),
            Fixtures.entry(id: "4", film: f, watched: nil),
        ])
        let stats = StatsEngine.compute(history)
        #expect(stats.heatmap[DayKey(year: 2024, month: 3, day: 1)] == 2)
        #expect(stats.heatmap[DayKey(year: 2024, month: 3, day: 2)] == 1)
        #expect(stats.heatmap.count == 2)
    }

    @Test("empty / no-date history -> zero streaks, empty heatmap")
    func emptyStreaks() {
        let f = Fixtures.film(id: "f")
        let stats = StatsEngine.compute(Fixtures.history([
            Fixtures.entry(id: "1", film: f, watched: nil),
        ]))
        #expect(stats.heatmap.isEmpty)
        #expect(stats.longestStreakDays == 0)
        #expect(stats.currentStreakDays == 0)
    }

    @Test("single watch -> both streaks 1")
    func singleWatch() {
        let f = Fixtures.film(id: "f")
        let stats = StatsEngine.compute(Fixtures.history([
            Fixtures.entry(id: "1", film: f, watched: "2024-06-15"),
        ]))
        #expect(stats.longestStreakDays == 1)
        #expect(stats.currentStreakDays == 1)
    }

    @Test("longest streak across a gap; current streak ends at most recent day")
    func streaksWithGap() {
        let f = Fixtures.film(id: "f")
        // 3-day run, gap, then 2-day run ending at latest date.
        let history = Fixtures.history([
            Fixtures.entry(id: "1", film: f, watched: "2024-01-01"),
            Fixtures.entry(id: "2", film: f, watched: "2024-01-02"),
            Fixtures.entry(id: "3", film: f, watched: "2024-01-03"),
            Fixtures.entry(id: "4", film: f, watched: "2024-01-10"),
            Fixtures.entry(id: "5", film: f, watched: "2024-01-11"),
        ])
        let stats = StatsEngine.compute(history)
        #expect(stats.longestStreakDays == 3)
        #expect(stats.currentStreakDays == 2)
    }

    @Test("multiple watches same day don't inflate streak; month boundary works")
    func sameDayAndMonthBoundary() {
        let f = Fixtures.film(id: "f")
        let history = Fixtures.history([
            Fixtures.entry(id: "1", film: f, watched: "2024-01-31"),
            Fixtures.entry(id: "2", film: f, watched: "2024-01-31"), // dup day
            Fixtures.entry(id: "3", film: f, watched: "2024-02-01"), // next day across month
            Fixtures.entry(id: "4", film: f, watched: "2024-02-02"),
        ])
        let stats = StatsEngine.compute(history)
        #expect(stats.longestStreakDays == 3) // Jan31, Feb1, Feb2
        #expect(stats.currentStreakDays == 3)
    }

    @Test("longest run is the latest run; current still that run")
    func longestIsLatest() {
        let f = Fixtures.film(id: "f")
        let history = Fixtures.history([
            Fixtures.entry(id: "1", film: f, watched: "2024-05-01"),
            Fixtures.entry(id: "2", film: f, watched: "2024-05-05"),
            Fixtures.entry(id: "3", film: f, watched: "2024-05-06"),
            Fixtures.entry(id: "4", film: f, watched: "2024-05-07"),
        ])
        let stats = StatsEngine.compute(history)
        #expect(stats.longestStreakDays == 3)
        #expect(stats.currentStreakDays == 3)
    }
}
