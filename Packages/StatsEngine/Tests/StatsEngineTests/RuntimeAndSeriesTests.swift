import Foundation
import Testing
import MiseCore
@testable import StatsEngine

@Suite("RuntimeAndSeries")
struct RuntimeAndSeriesTests {
    @Test("total runtime sums entries with runtime, ignores missing")
    func totalRuntime() {
        let a = Fixtures.film(id: "a", runtime: 120)
        let b = Fixtures.film(id: "b", runtime: 90)
        let c = Fixtures.film(id: "c", runtime: nil)
        let history = Fixtures.history([
            Fixtures.entry(id: "1", film: a, watched: "2023-01-10"),
            Fixtures.entry(id: "2", film: b, watched: "2024-05-01"),
            Fixtures.entry(id: "3", film: c, watched: "2024-05-02"), // no runtime
        ])
        let stats = StatsEngine.compute(history)
        #expect(stats.totalRuntimeMinutes == 210)
    }

    @Test("runtime per year keyed by watched year, needs runtime and date")
    func runtimePerYear() {
        let a = Fixtures.film(id: "a", runtime: 120)
        let b = Fixtures.film(id: "b", runtime: 90)
        let noDate = Fixtures.film(id: "n", runtime: 100)
        let history = Fixtures.history([
            Fixtures.entry(id: "1", film: a, watched: "2023-01-10"),
            Fixtures.entry(id: "2", film: b, watched: "2023-12-31"),
            Fixtures.entry(id: "3", film: a, watched: "2024-02-02"),
            Fixtures.entry(id: "4", film: noDate, watched: nil), // ignored (no date)
        ])
        let stats = StatsEngine.compute(history)
        #expect(stats.runtimeMinutesPerYear == [2023: 210, 2024: 120])
        #expect(stats.totalRuntimeMinutes == 430) // noDate still counts toward total
    }

    @Test("films per year and per month from watched date")
    func timeSeries() {
        let f = Fixtures.film(id: "f")
        let history = Fixtures.history([
            Fixtures.entry(id: "1", film: f, watched: "2023-01-05"),
            Fixtures.entry(id: "2", film: f, watched: "2023-01-20"),
            Fixtures.entry(id: "3", film: f, watched: "2023-03-15"),
            Fixtures.entry(id: "4", film: f, watched: "2024-03-15"),
            Fixtures.entry(id: "5", film: f, watched: nil), // ignored
        ])
        let stats = StatsEngine.compute(history)
        #expect(stats.filmsPerYear == [2023: 3, 2024: 1])
        #expect(stats.filmsPerMonth[MonthKey(year: 2023, month: 1)] == 2)
        #expect(stats.filmsPerMonth[MonthKey(year: 2023, month: 3)] == 1)
        #expect(stats.filmsPerMonth[MonthKey(year: 2024, month: 3)] == 1)
        #expect(stats.filmsPerMonth.count == 3)
    }
}
