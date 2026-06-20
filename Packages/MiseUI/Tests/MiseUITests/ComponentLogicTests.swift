import Testing
import Foundation
import ThemeKit
import MiseCore
@testable import MiseUI

@Suite("Heatmap intensity bucketing")
struct HeatmapBucketTests {

    @Test("zero count is bucket 0")
    func zero() {
        #expect(HeatmapGridView.bucket(for: 0, max: 10) == 0)
    }

    @Test("any positive count with zero max is bucket 0 (no data)")
    func zeroMax() {
        #expect(HeatmapGridView.bucket(for: 3, max: 0) == 0)
    }

    @Test("max count lands in the top bucket")
    func topBucket() {
        #expect(HeatmapGridView.bucket(for: 10, max: 10) == HeatmapGridView.bucketCount)
    }

    @Test("smallest positive count is at least bucket 1")
    func minBucket() {
        #expect(HeatmapGridView.bucket(for: 1, max: 100) == 1)
    }

    @Test("buckets are non-decreasing in count")
    func monotonic() {
        let maxCount = 20
        var last = 0
        for c in 0...maxCount {
            let b = HeatmapGridView.bucket(for: c, max: maxCount)
            #expect(b >= last)
            #expect(b <= HeatmapGridView.bucketCount)
            last = b
        }
    }
}

@Suite("DayKey ordering")
struct DayKeyTests {

    @Test("compares chronologically")
    func chronological() {
        #expect(DayKey(year: 2024, month: 12, day: 31) < DayKey(year: 2025, month: 1, day: 1))
        #expect(DayKey(year: 2025, month: 1, day: 1) < DayKey(year: 2025, month: 1, day: 2))
        #expect(DayKey(year: 2025, month: 1, day: 1) < DayKey(year: 2025, month: 2, day: 1))
    }

    @Test("built from a Date matches its calendar components")
    func fromDate() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let date = cal.date(from: DateComponents(year: 2026, month: 6, day: 20))!
        let key = DayKey(date: date, calendar: cal)
        #expect(key == DayKey(year: 2026, month: 6, day: 20))
    }
}

@Suite("Star rating fill logic")
struct StarFillTests {

    @Test("five full stars for 10 half-stars")
    func fullFive() {
        for i in 0..<5 {
            #expect(StarRatingView.fill(forStarIndex: i, halfStars: 10) == 1.0)
        }
    }

    @Test("4.5 stars -> four full and one half")
    func fourAndHalf() {
        let fills = (0..<5).map { StarRatingView.fill(forStarIndex: $0, halfStars: 9) }
        #expect(fills == [1.0, 1.0, 1.0, 1.0, 0.5])
    }

    @Test("half star -> first half, rest empty")
    func halfOnly() {
        let fills = (0..<5).map { StarRatingView.fill(forStarIndex: $0, halfStars: 1) }
        #expect(fills == [0.5, 0.0, 0.0, 0.0, 0.0])
    }

    @Test("sum of fills equals the rating in stars", arguments: 1...10)
    func sumMatchesStars(halfStars: Int) {
        let total = (0..<5).reduce(0.0) { $0 + StarRatingView.fill(forStarIndex: $1, halfStars: halfStars) }
        #expect(total == Double(halfStars) / 2.0)
    }
}

@Suite("PosterWall layout metrics")
struct PosterWallMetricsTests {

    @Test("wall style packs posters tighter than grid")
    func wallTighter() {
        #expect(PosterWallView.posterWidth(for: .wall) < PosterWallView.posterWidth(for: .grid))
        #expect(PosterWallView.gap(for: .wall, densityScale: 1) < PosterWallView.gap(for: .grid, densityScale: 1))
    }

    @Test("shelf uses the largest posters")
    func shelfLargest() {
        let widths = PosterWallStyle.allCases.map { PosterWallView.posterWidth(for: $0) }
        #expect(PosterWallView.posterWidth(for: .shelf) == widths.max())
    }

    @Test("gap scales with density")
    func gapDensity() {
        let normal = PosterWallView.gap(for: .grid, densityScale: 1)
        let dense = PosterWallView.gap(for: .grid, densityScale: 2)
        #expect(dense == normal * 2)
    }
}

@Suite("Preview data sanity")
struct PreviewDataTests {

    @Test("films and diary are populated")
    func populated() {
        #expect(MiseUIPreviewData.films.count >= 10)
        #expect(!MiseUIPreviewData.diary.isEmpty)
        #expect(MiseUIPreviewData.filmWithPoster.posterURL != nil)
        #expect(MiseUIPreviewData.filmNoPoster.posterURL == nil)
    }

    @Test("heatmap counts are all positive and within a year span")
    func heatmap() {
        let counts = MiseUIPreviewData.heatmapCounts
        #expect(!counts.isEmpty)
        #expect(counts.values.allSatisfy { $0 > 0 })
    }
}
