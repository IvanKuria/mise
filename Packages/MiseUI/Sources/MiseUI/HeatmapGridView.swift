import SwiftUI

/// A calendar day, independent of time zone and time-of-day, used as the key for
/// the contributions-style heatmap. Comparable in chronological order.
public struct DayKey: Hashable, Comparable, Sendable {
    public let year: Int
    public let month: Int
    public let day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    /// Builds a `DayKey` from a `Date` using the given calendar (default current).
    public init(date: Date, calendar: Calendar = .current) {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        self.init(year: c.year ?? 0, month: c.month ?? 0, day: c.day ?? 0)
    }

    public static func < (lhs: DayKey, rhs: DayKey) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }
}

/// A GitHub-contributions-style grid of activity. Keyed by `DayKey`; each cell's
/// color interpolates from the theme background toward the accent by intensity
/// bucket. Lay out is column-per-week, row-per-weekday.
public struct HeatmapGridView: View {
    @Environment(\.miseTheme) private var theme

    private let counts: [DayKey: Int]
    private let cellSize: CGFloat

    public init(counts: [DayKey: Int], cellSize: CGFloat = 12) {
        self.counts = counts
        self.cellSize = cellSize
    }

    /// Number of intensity buckets above zero (so 5 total levels: 0...4).
    public static let bucketCount = 4

    /// Pure: maps a count to an intensity bucket in `0...bucketCount`, given the
    /// maximum count in the data set. 0 -> 0; otherwise a proportional bucket in
    /// `1...bucketCount`.
    public static func bucket(for count: Int, max maxCount: Int) -> Int {
        guard count > 0 else { return 0 }
        guard maxCount > 0 else { return 0 }
        let fraction = Double(count) / Double(maxCount)
        let bucket = Int((fraction * Double(bucketCount)).rounded(.up))
        return min(bucketCount, max(1, bucket))
    }

    private var maxCount: Int { counts.values.max() ?? 0 }

    /// The sorted, contiguous span of days from the earliest to latest key,
    /// aligned to start on a Sunday so columns are clean weeks.
    private var days: [DayKey] {
        guard let minKey = counts.keys.min(), let maxKey = counts.keys.max() else {
            return []
        }
        let calendar = Calendar(identifier: .gregorian)
        guard
            let start = calendar.date(from: DateComponents(year: minKey.year, month: minKey.month, day: minKey.day)),
            let end = calendar.date(from: DateComponents(year: maxKey.year, month: maxKey.month, day: maxKey.day))
        else { return [] }

        // Back up to the Sunday on/before start.
        let weekday = calendar.component(.weekday, from: start) // 1 == Sunday
        guard let gridStart = calendar.date(byAdding: .day, value: -(weekday - 1), to: start) else {
            return []
        }

        var result: [DayKey] = []
        var cursor = gridStart
        while cursor <= end {
            result.append(DayKey(date: cursor, calendar: calendar))
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return result
    }

    /// Days chunked into weeks (columns) of 7.
    private var weeks: [[DayKey]] {
        stride(from: 0, to: days.count, by: 7).map {
            Array(days[$0..<min($0 + 7, days.count)])
        }
    }

    private func color(for day: DayKey) -> Color {
        let count = counts[day] ?? 0
        let b = HeatmapGridView.bucket(for: count, max: maxCount)
        guard b > 0 else { return theme.surface }
        let t = Double(b) / Double(HeatmapGridView.bucketCount)
        // Interpolate from a low surface tint up to the accent.
        return theme.accent.opacity(0.25 + 0.75 * t)
    }

    public var body: some View {
        let gap = cellSize * 0.22
        HStack(alignment: .top, spacing: gap) {
            ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                VStack(spacing: gap) {
                    ForEach(Array(week.enumerated()), id: \.offset) { _, day in
                        RoundedRectangle(cornerRadius: cellSize * 0.2, style: .continuous)
                            .fill(color(for: day))
                            .frame(width: cellSize, height: cellSize)
                    }
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Activity heatmap")
    }
}

#Preview("HeatmapGridView") {
    HeatmapGridView(counts: MiseUIPreviewData.heatmapCounts)
        .padding(32)
        .background(MiseTheme(.noir).background)
        .miseTheme(.noir)
}
