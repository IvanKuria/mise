import Foundation
import StatsEngine
import MiseUI

/// Pure presentation helpers for the dashboard: number/label formatting and the
/// data-shaping that bridges `StatsEngine.FilmStats` into renderable rows. Kept
/// free of SwiftUI so it can be unit-tested in isolation.
public enum DashboardFormat {

    // MARK: - Counts & runtime

    /// A grouped integer, e.g. `1284 -> "1,284"`. Uses a fixed, locale-independent
    /// grouping so output is deterministic across machines.
    public static func count(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    /// Total runtime expressed as whole days (1 day == 1,440 minutes), rounded to
    /// one decimal place. `0` minutes -> `"0"`.
    public static func runtimeDays(minutes: Int) -> String {
        guard minutes > 0 else { return "0" }
        let days = Double(minutes) / 1_440.0
        return decimal(days, places: 1)
    }

    /// A caption for the runtime card, e.g. `"2,041 hrs"`. Hours are floored.
    public static func runtimeHoursCaption(minutes: Int) -> String {
        let hours = minutes / 60
        return "\(count(hours)) hrs total"
    }

    // MARK: - Ratings

    /// The member's average rating in stars over the histogram, or `nil` when no
    /// films are rated. The histogram is keyed by half-stars (1...10).
    public static func averageStars(histogram: [Int: Int]) -> Double? {
        let total = histogram.values.reduce(0, +)
        guard total > 0 else { return nil }
        let sumHalfStars = histogram.reduce(0) { $0 + $1.key * $1.value }
        return Double(sumHalfStars) / 2.0 / Double(total)
    }

    /// Formats an average rating in stars for a headline card, e.g. `"3.8★"`.
    /// `nil` -> `"—"`.
    public static func averageStarsLabel(_ stars: Double?) -> String {
        guard let stars else { return "—" }
        return "\(decimal(stars, places: 1))★"
    }

    /// A compact star glyph string for a half-star count, e.g. `7 -> "★★★½"`.
    public static func starGlyphs(halfStars: Int) -> String {
        let clamped = max(0, halfStars)
        let full = clamped / 2
        let hasHalf = clamped % 2 == 1
        return String(repeating: "★", count: full) + (hasHalf ? "½" : "")
    }

    /// The ratings histogram as ordered bars over every half-star bucket 1...10,
    /// filling absent buckets with zero so the chart axis is always complete.
    public static func ratingBars(histogram: [Int: Int]) -> [RatingBar] {
        (1...10).map { half in
            RatingBar(halfStars: half, label: starGlyphs(halfStars: half), count: histogram[half] ?? 0)
        }
    }

    // MARK: - Contrarian

    /// A human-readable label for the contrarian score (mean of member minus crowd,
    /// in stars). Positive means the member rates more generously than the crowd.
    public static func contrarianLabel(_ score: Double?) -> String {
        guard let score else { return "—" }
        let magnitude = decimal(abs(score), places: 1)
        if abs(score) < 0.05 { return "In step" }
        return score > 0 ? "+\(magnitude)★ kinder" : "−\(magnitude)★ harsher"
    }

    /// A one-line caption describing how the member's taste compares to the crowd.
    public static func contrarianCaption(_ score: Double?) -> String {
        guard let score else { return "Needs community ratings" }
        if abs(score) < 0.05 { return "Right with the crowd" }
        return score > 0 ? "You rate above the crowd" : "You rate below the crowd"
    }

    // MARK: - Breakdowns

    /// Genre breakdown as bars sorted by count descending (ties by name ascending),
    /// limited to `limit` entries.
    public static func genreBars(_ breakdown: [String: CountAverage], limit: Int = 8) -> [BreakdownBar] {
        breakdown
            .map { BreakdownBar(label: $0.key, count: $0.value.count, averageRating: $0.value.averageRating) }
            .sorted(by: breakdownOrder)
            .prefix(limit)
            .map { $0 }
    }

    /// Decade breakdown as bars sorted chronologically (oldest first), labelled
    /// `"1980s"` etc.
    public static func decadeBars(_ breakdown: [Int: CountAverage]) -> [BreakdownBar] {
        breakdown
            .sorted { $0.key < $1.key }
            .map { BreakdownBar(label: "\($0.key)s", count: $0.value.count, averageRating: $0.value.averageRating) }
    }

    /// Sort: count desc, then label asc. Stable, deterministic.
    static func breakdownOrder(_ lhs: BreakdownBar, _ rhs: BreakdownBar) -> Bool {
        if lhs.count != rhs.count { return lhs.count > rhs.count }
        return lhs.label < rhs.label
    }

    /// A caption like `"12 films · 4.1★ avg"` for a person/breakdown row.
    public static func aggregateCaption(count: Int, averageRating: Double?) -> String {
        let filmsPart = "\(count) film\(count == 1 ? "" : "s")"
        guard let averageRating else { return filmsPart }
        return "\(filmsPart) · \(decimal(averageRating, places: 1))★ avg"
    }

    // MARK: - Heatmap bridging

    /// Maps a `FilmStats` heatmap (keyed by the engine's own `DayKey`) into MiseUI's
    /// `DayKey` space so it can be rendered by `HeatmapGridView`. The engine's
    /// `DayKey` is read via `FilmStats.heatmap` to avoid the module-vs-enum name
    /// clash on the `StatsEngine` identifier.
    public static func heatmapCounts(_ stats: FilmStats) -> [MiseUI.DayKey: Int] {
        var result: [MiseUI.DayKey: Int] = [:]
        for (key, value) in stats.heatmap {
            result[MiseUI.DayKey(year: key.year, month: key.month, day: key.day)] = value
        }
        return result
    }

    // MARK: - Number helpers

    /// Locale-independent fixed-decimal formatting, e.g. `decimal(3.84, places: 1) -> "3.8"`.
    static func decimal(_ value: Double, places: Int) -> String {
        String(format: "%.\(places)f", value)
    }
}

/// One bar of the ratings histogram, over a half-star bucket (1...10).
public struct RatingBar: Hashable, Sendable, Identifiable {
    public var id: Int { halfStars }
    public let halfStars: Int
    /// A star-glyph label for the axis, e.g. `"★★★½"`.
    public let label: String
    public let count: Int

    public init(halfStars: Int, label: String, count: Int) {
        self.halfStars = halfStars
        self.label = label
        self.count = count
    }
}

/// A labelled bar for genre / decade breakdowns, carrying its average rating.
public struct BreakdownBar: Hashable, Sendable, Identifiable {
    public var id: String { label }
    public let label: String
    public let count: Int
    public let averageRating: Double?

    public init(label: String, count: Int, averageRating: Double?) {
        self.label = label
        self.count = count
        self.averageRating = averageRating
    }
}
