import Testing
import Foundation
@testable import DashboardFeature
import StatsEngine
import MiseUI

@Suite("DashboardFormat")
struct DashboardFormatTests {

    // MARK: - Counts & runtime

    @Test func countGroupsThousands() {
        #expect(DashboardFormat.count(1284) == "1,284")
        #expect(DashboardFormat.count(0) == "0")
        #expect(DashboardFormat.count(999) == "999")
        #expect(DashboardFormat.count(1_000_000) == "1,000,000")
    }

    @Test func runtimeDaysFromMinutes() {
        #expect(DashboardFormat.runtimeDays(minutes: 0) == "0")
        #expect(DashboardFormat.runtimeDays(minutes: 1440) == "1.0")   // exactly one day
        #expect(DashboardFormat.runtimeDays(minutes: 2160) == "1.5")   // 36 hours
        #expect(DashboardFormat.runtimeDays(minutes: 720) == "0.5")    // half a day
    }

    @Test func runtimeHoursCaption() {
        #expect(DashboardFormat.runtimeHoursCaption(minutes: 0) == "0 hrs total")
        #expect(DashboardFormat.runtimeHoursCaption(minutes: 90) == "1 hrs total")
        #expect(DashboardFormat.runtimeHoursCaption(minutes: 6000) == "100 hrs total")
    }

    // MARK: - Ratings

    @Test func averageStarsOverHistogram() {
        // Two films: one at 5 half-stars (2.5★), one at 9 half-stars (4.5★) -> 3.5★
        let histogram = [5: 1, 9: 1]
        #expect(DashboardFormat.averageStars(histogram: histogram) == 3.5)
    }

    @Test func averageStarsWeightsByCount() {
        // 8 half-stars (4.0★) x3, 4 half-stars (2.0★) x1 -> (12+12+12+4)/2 ... weighted
        let histogram = [8: 3, 4: 1]
        let avg = DashboardFormat.averageStars(histogram: histogram)
        // half-star sum = 8*3 + 4*1 = 28; /2 = 14 stars; /4 films = 3.5
        #expect(avg == 3.5)
    }

    @Test func averageStarsEmptyIsNil() {
        #expect(DashboardFormat.averageStars(histogram: [:]) == nil)
    }

    @Test func averageStarsLabelFormatting() {
        #expect(DashboardFormat.averageStarsLabel(3.84) == "3.8★")
        #expect(DashboardFormat.averageStarsLabel(nil) == "—")
    }

    @Test func starGlyphs() {
        #expect(DashboardFormat.starGlyphs(halfStars: 10) == "★★★★★")
        #expect(DashboardFormat.starGlyphs(halfStars: 7) == "★★★½")
        #expect(DashboardFormat.starGlyphs(halfStars: 1) == "½")
        #expect(DashboardFormat.starGlyphs(halfStars: 0) == "")
    }

    @Test func ratingBarsCoverAllBucketsInOrder() {
        let bars = DashboardFormat.ratingBars(histogram: [10: 5, 7: 2])
        #expect(bars.count == 10)
        #expect(bars.first?.halfStars == 1)
        #expect(bars.last?.halfStars == 10)
        #expect(bars.last?.count == 5)
        #expect(bars[6].count == 2)   // halfStars == 7
        #expect(bars[0].count == 0)   // absent bucket filled with zero
    }

    // MARK: - Contrarian

    @Test func contrarianLabelKinder() {
        #expect(DashboardFormat.contrarianLabel(0.4) == "+0.4★ kinder")
    }

    @Test func contrarianLabelHarsher() {
        #expect(DashboardFormat.contrarianLabel(-0.6) == "−0.6★ harsher")
    }

    @Test func contrarianLabelInStep() {
        #expect(DashboardFormat.contrarianLabel(0.0) == "In step")
        #expect(DashboardFormat.contrarianLabel(0.02) == "In step")
    }

    @Test func contrarianLabelNil() {
        #expect(DashboardFormat.contrarianLabel(nil) == "—")
    }

    @Test func contrarianCaption() {
        #expect(DashboardFormat.contrarianCaption(0.5) == "You rate above the crowd")
        #expect(DashboardFormat.contrarianCaption(-0.5) == "You rate below the crowd")
        #expect(DashboardFormat.contrarianCaption(0.0) == "Right with the crowd")
        #expect(DashboardFormat.contrarianCaption(nil) == "Needs community ratings")
    }

    // MARK: - Breakdowns

    @Test func genreBarsSortedByCountThenName() {
        let breakdown: [String: CountAverage] = [
            "Drama": CountAverage(count: 10, averageRating: 4.0),
            "Comedy": CountAverage(count: 3, averageRating: 3.5),
            "Action": CountAverage(count: 3, averageRating: 3.0),
        ]
        let bars = DashboardFormat.genreBars(breakdown)
        #expect(bars.map(\.label) == ["Drama", "Action", "Comedy"])  // 10, then ties by name
    }

    @Test func genreBarsRespectsLimit() {
        let breakdown = Dictionary(uniqueKeysWithValues: (0..<20).map {
            ("g\($0)", CountAverage(count: 20 - $0, averageRating: nil))
        })
        #expect(DashboardFormat.genreBars(breakdown, limit: 5).count == 5)
    }

    @Test func decadeBarsChronologicalAndLabelled() {
        let breakdown: [Int: CountAverage] = [
            2010: CountAverage(count: 4, averageRating: nil),
            1980: CountAverage(count: 2, averageRating: nil),
            2000: CountAverage(count: 6, averageRating: nil),
        ]
        let bars = DashboardFormat.decadeBars(breakdown)
        #expect(bars.map(\.label) == ["1980s", "2000s", "2010s"])
    }

    @Test func aggregateCaption() {
        #expect(DashboardFormat.aggregateCaption(count: 1, averageRating: nil) == "1 film")
        #expect(DashboardFormat.aggregateCaption(count: 12, averageRating: nil) == "12 films")
        #expect(DashboardFormat.aggregateCaption(count: 12, averageRating: 4.13) == "12 films · 4.1★ avg")
    }

    // MARK: - Heatmap bridging

    @Test func heatmapCountsMapsBetweenDayKeyTypes() {
        // The sample history's watch dates map into MiseUI DayKey space, preserving
        // the per-day counts and total.
        let stats = DashboardSampleData.stats
        let mapped = DashboardFormat.heatmapCounts(stats)
        #expect(mapped.count == stats.heatmap.count)
        #expect(!mapped.isEmpty)
        #expect(mapped.values.reduce(0, +) == stats.heatmap.values.reduce(0, +))
    }

    @Test func heatmapCountsEmptyHistory() {
        let stats = StatsEngine.compute(DashboardSampleData.emptyHistory)
        #expect(DashboardFormat.heatmapCounts(stats).isEmpty)
    }
}

@Suite("DashboardSampleData")
struct DashboardSampleDataTests {
    @Test func sampleHistoryIsNonEmptyAndComputes() {
        let stats = DashboardSampleData.stats
        #expect(stats.totalLogged > 0)
        #expect(!stats.hottestTakes.isEmpty)
        #expect(!stats.genreBreakdown.isEmpty)
        #expect(!stats.topDirectors.isEmpty)
    }

    @Test func emptyHistoryComputesToZero() {
        let stats = StatsEngine.compute(DashboardSampleData.emptyHistory)
        #expect(stats.totalLogged == 0)
    }
}
