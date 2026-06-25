import SwiftUI
import MiseCore

/// A GitHub-style contribution heatmap of films watched per day — the signature
/// visual of the notch bar. Unlike a rolling-52-week window, this shows a TRUE
/// CALENDAR YEAR (Jan 1 → Dec 31) with a year switcher, so January is always the
/// leftmost column and the grid looks structurally identical every year.
/// Sits on the black notch panel, so it draws on a clear background.
/// Sized to fit ≈ 664pt wide × compact height.
struct ContributionHeatmapPanel: View {
    let history: WatchHistory

    @State private var selectedYear: Int
    @State private var hoveredDay: Date?
    @State private var hoveredCount = 0

    init(history: WatchHistory) {
        self.history = history

        // Initialize selectedYear to the most recent year present in the diary
        // (over watchedDate ?? loggedDate), or the current year if no entries.
        let cal = Calendar.current
        var maxYear = cal.component(.year, from: Date())
        var found = false
        for entry in history.diary {
            guard let date = entry.watchedDate ?? entry.loggedDate else { continue }
            let year = cal.component(.year, from: date)
            if !found || year > maxYear {
                maxYear = year
                found = true
            }
        }
        _selectedYear = State(initialValue: maxYear)
    }

    // MARK: - Layout constants

    private let cell: CGFloat = 9
    private let gap: CGFloat = 3
    private let rows = 7  // Sun…Sat

    private var columnWidth: CGFloat { cell + gap }

    // MARK: - Derived data

    /// Films watched per day, keyed by start-of-day.
    private var countsByDay: [Date: Int] {
        let cal = Calendar.current
        var result: [Date: Int] = [:]
        for entry in history.diary {
            guard let date = entry.watchedDate ?? entry.loggedDate else { continue }
            let day = cal.startOfDay(for: date)
            result[day, default: 0] += 1
        }
        return result
    }

    /// The full set of years present in the diary, plus the current year, used to
    /// bound the year switcher: [minYear, maxYear].
    private var yearBounds: (min: Int, max: Int) {
        let cal = Calendar.current
        let currentYear = cal.component(.year, from: Date())
        var minYear = currentYear
        for entry in history.diary {
            guard let date = entry.watchedDate ?? entry.loggedDate else { continue }
            let year = cal.component(.year, from: date)
            if year < minYear { minYear = year }
        }
        // maxYear is always the current year (never let the user browse the future).
        return (min: min(minYear, currentYear), max: currentYear)
    }

    /// Jan 1 (start of day) of the selected year.
    private var jan1: Date {
        let cal = Calendar.current
        let comps = DateComponents(year: selectedYear, month: 1, day: 1)
        return cal.date(from: comps).map(cal.startOfDay(for:)) ?? cal.startOfDay(for: Date())
    }

    /// Dec 31 (start of day) of the selected year.
    private var dec31: Date {
        let cal = Calendar.current
        let comps = DateComponents(year: selectedYear, month: 12, day: 31)
        return cal.date(from: comps).map(cal.startOfDay(for:)) ?? cal.startOfDay(for: Date())
    }

    /// The Sunday on/just before Jan 1 of the selected year — the top-left of the grid.
    private var gridStart: Date {
        let cal = Calendar.current
        let start = jan1
        // weekday: 1 = Sunday in Gregorian. Back up to the preceding Sunday.
        let weekday = cal.component(.weekday, from: start)
        let backUp = weekday - 1
        return cal.date(byAdding: .day, value: -backUp, to: start) ?? start
    }

    /// Number of week-columns needed to cover the week containing Jan 1 through
    /// the week containing Dec 31 (~53). Computed so leading/trailing partial weeks
    /// are always included, keeping the grid rectangular.
    private var weeks: Int {
        let cal = Calendar.current
        let dayCount = (cal.dateComponents([.day], from: gridStart, to: dec31).day ?? 0)
        // dayCount is days from gridStart (a Sunday) to Dec 31. Add the remainder of
        // Dec 31's week, then divide by 7.
        return (dayCount / 7) + 1
    }

    /// Intensity → level. 0→0, 1→1, 2→2, 3–4→3, 5+→4.
    private func level(for count: Int) -> Int {
        switch count {
        case ...0: return 0
        case 1: return 1
        case 2: return 2
        case 3, 4: return 3
        default: return 4
        }
    }

    /// The date at grid column (week) and row (weekday offset from Sunday).
    private func date(week: Int, row: Int) -> Date {
        let cal = Calendar.current
        let offset = week * 7 + row
        return cal.date(byAdding: .day, value: offset, to: gridStart) ?? gridStart
    }

    /// Whether a date falls inside [Jan 1, Dec 31] of the selected year.
    private func inYear(_ day: Date) -> Bool {
        day >= jan1 && day <= dec31
    }

    /// Total films logged in the selected calendar year.
    private func totalInYear(_ counts: [Date: Int]) -> Int {
        var total = 0
        for (day, count) in counts where inYear(day) {
            total += count
        }
        return total
    }

    // MARK: - Body

    var body: some View {
        let counts = countsByDay
        let total = totalInYear(counts)
        let weekCount = weeks

        VStack(alignment: .leading, spacing: 8) {
            header(total: total)

            VStack(alignment: .leading, spacing: 4) {
                monthLabels(weekCount: weekCount)

                HStack(alignment: .top, spacing: gap) {
                    ForEach(0..<weekCount, id: \.self) { week in
                        VStack(spacing: gap) {
                            ForEach(0..<rows, id: \.self) { row in
                                cellView(week: week, row: row, counts: counts)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Header: year switcher (left) · hover readout · legend (right)

    private func header(total: Int) -> some View {
        let bounds = yearBounds

        return HStack(spacing: 10) {
            yearSwitcher(bounds: bounds)

            if let day = hoveredDay {
                Text(dayLabel(day))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(NotchStyle.textPrimary)
                Text(hoveredCount == 1 ? "1 film" : "\(hoveredCount) films")
                    .font(.system(size: 11))
                    .foregroundColor(NotchStyle.textSecondary)
            } else {
                Text("\(total)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(NotchStyle.textPrimary)
                Text(total == 1 ? "film in \(verbatimYear)" : "films in \(verbatimYear)")
                    .font(.system(size: 11))
                    .foregroundColor(NotchStyle.textSecondary)
            }

            Spacer()

            legend
        }
    }

    /// `‹  2026  ›` control. Chevrons disable + dim at the bounds.
    private func yearSwitcher(bounds: (min: Int, max: Int)) -> some View {
        let canGoPrev = selectedYear > bounds.min
        let canGoNext = selectedYear < bounds.max

        return HStack(spacing: 4) {
            HoverButton(systemName: "chevron.left") {
                if canGoPrev { selectedYear -= 1; clearHover() }
            }
            .opacity(canGoPrev ? 1 : 0.25)
            .disabled(!canGoPrev)

            Text(verbatimYear)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(NotchStyle.textPrimary)
                .frame(minWidth: 34)

            HoverButton(systemName: "chevron.right") {
                if canGoNext { selectedYear += 1; clearHover() }
            }
            .opacity(canGoNext ? 1 : 0.25)
            .disabled(!canGoNext)
        }
    }

    private var legend: some View {
        HStack(spacing: 4) {
            Text("Less")
                .font(.system(size: 8))
                .foregroundColor(NotchStyle.textTertiary)
            ForEach(0..<5, id: \.self) { lvl in
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(NotchStyle.heatColor(level: lvl))
                    .frame(width: cell, height: cell)
            }
            Text("More")
                .font(.system(size: 8))
                .foregroundColor(NotchStyle.textTertiary)
        }
    }

    private func clearHover() {
        hoveredDay = nil
        hoveredCount = 0
    }

    /// The selected year as a plain string (no thousands separator).
    private var verbatimYear: String { String(selectedYear) }

    // MARK: - Month labels

    private func monthLabels(weekCount: Int) -> some View {
        let cal = Calendar.current
        let df = DateFormatter()
        df.dateFormat = "MMM"

        // Label the column where each month first appears *inside the year*, but
        // enforce a minimum column gap so adjacent labels never collide/squish.
        // A "Mmm" label is ~22pt wide ≈ 2 columns; require ≥ 3.
        var labels: [(week: Int, text: String)] = []
        var previousMonth = -1
        var lastLabeledWeek = -10
        for week in 0..<weekCount {
            let columnDate = date(week: week, row: 0)
            // Use the first in-year day of this column so leading partial weeks
            // (which belong to the prior year) don't mislabel January.
            guard let inYearDate = firstInYearDate(week: week) else {
                // Whole column is outside the year (shouldn't happen, but be safe).
                previousMonth = cal.component(.month, from: columnDate)
                continue
            }
            let month = cal.component(.month, from: inYearDate)
            if month != previousMonth {
                previousMonth = month
                if week - lastLabeledWeek >= 3 {
                    labels.append((week, df.string(from: inYearDate)))
                    lastLabeledWeek = week
                }
            }
        }

        return ZStack(alignment: .topLeading) {
            ForEach(labels, id: \.week) { label in
                Text(label.text)
                    .font(.system(size: 9))
                    .foregroundColor(NotchStyle.textTertiary)
                    .fixedSize()
                    .offset(x: CGFloat(label.week) * columnWidth)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 12, alignment: .topLeading)
    }

    /// The first day within [Jan 1, Dec 31] in a given week-column, or nil if the
    /// whole column lies outside the year.
    private func firstInYearDate(week: Int) -> Date? {
        for row in 0..<rows {
            let day = date(week: week, row: row)
            if inYear(day) { return day }
        }
        return nil
    }

    // MARK: - Cell

    @ViewBuilder
    private func cellView(week: Int, row: Int, counts: [Date: Int]) -> some View {
        let day = date(week: week, row: row)

        if !inYear(day) {
            // Leading/trailing partial-week days from adjacent years: clear so the
            // grid stays rectangular without coloring days outside the year.
            Color.clear
                .frame(width: cell, height: cell)
        } else {
            let count = counts[day] ?? 0
            RoundedRectangle(cornerRadius: 2.5)
                .fill(NotchStyle.heatColor(level: level(for: count)))
                .frame(width: cell, height: cell)
                .overlay(
                    RoundedRectangle(cornerRadius: 2.5)
                        .strokeBorder(.white.opacity(hoveredDay == day ? 0.7 : 0), lineWidth: 1)
                )
                .onHover { inside in
                    if inside { hoveredDay = day; hoveredCount = count }
                    else if hoveredDay == day { hoveredDay = nil }
                }
        }
    }

    private func dayLabel(_ day: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "MMM d, yyyy"
        return df.string(from: day)
    }
}

#Preview {
    ContributionHeatmapPanel(history: SampleData.history())
        .padding(16)
        .frame(width: 664, height: 150)
        .background(Color.black)
}
