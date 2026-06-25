import SwiftUI
import MiseCore

/// A GitHub-style contribution heatmap of films watched per day — the signature
/// visual of the notch bar. Sits on the black notch panel, so it draws on a
/// clear background. Sized to fit ≈ 660pt wide × ~150pt tall.
struct ContributionHeatmapPanel: View {
    let history: WatchHistory

    init(history: WatchHistory) {
        self.history = history
    }

    // MARK: - Layout constants

    private let weeks = 53          // a full rolling year, GitHub-style
    private let cell: CGFloat = 9
    private let gap: CGFloat = 3
    private let rows = 7  // Sun…Sat

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

    /// The Sunday on/just before (today − (weeks−1)*7), the top-left of the grid.
    private var gridStart: Date {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let windowStart = cal.date(byAdding: .day, value: -(weeks - 1) * 7, to: today) ?? today
        // weekday: 1 = Sunday in Gregorian. Back up to the preceding Sunday.
        let weekday = cal.component(.weekday, from: windowStart)
        let backUp = weekday - 1
        return cal.date(byAdding: .day, value: -backUp, to: windowStart) ?? windowStart
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

    // MARK: - Body

    var body: some View {
        let counts = countsByDay
        let today = Calendar.current.startOfDay(for: Date())
        let total = counts.values.reduce(0, +)

        VStack(alignment: .leading, spacing: 8) {
            header(total: total)

            VStack(alignment: .leading, spacing: 4) {
                monthLabels(today: today)

                HStack(alignment: .top, spacing: gap) {
                    ForEach(0..<weeks, id: \.self) { week in
                        VStack(spacing: gap) {
                            ForEach(0..<rows, id: \.self) { row in
                                cellView(week: week, row: row, counts: counts, today: today)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Header + legend

    private func header(total: Int) -> some View {
        HStack(spacing: 6) {
            Text("\(total)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(NotchStyle.textPrimary)
            Text("films in the last year")
                .font(.system(size: 11))
                .foregroundColor(NotchStyle.textSecondary)

            Spacer()

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
    }

    // MARK: - Month labels

    private func monthLabels(today: Date) -> some View {
        let cal = Calendar.current
        let columnWidth = cell + gap
        let df = DateFormatter()
        df.dateFormat = "MMM"

        // Label the column where each new month begins, but enforce a minimum
        // column gap so adjacent labels (e.g. Jul/Aug at the window edge) never
        // collide. A "Mmm" label is ~22pt wide ≈ 2 columns; require ≥ 3.
        var labels: [(week: Int, text: String)] = []
        var previousMonth = -1
        var lastLabeledWeek = -10
        for week in 0..<weeks {
            let columnDate = date(week: week, row: 0)
            let month = cal.component(.month, from: columnDate)
            if month != previousMonth {
                previousMonth = month
                if week - lastLabeledWeek >= 3 {
                    labels.append((week, df.string(from: columnDate)))
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

    // MARK: - Cell

    @ViewBuilder
    private func cellView(week: Int, row: Int, counts: [Date: Int], today: Date) -> some View {
        let day = date(week: week, row: row)

        if day > today {
            // Future days: clear placeholder keeps the grid rectangular.
            Color.clear
                .frame(width: cell, height: cell)
        } else {
            let count = counts[day] ?? 0
            RoundedRectangle(cornerRadius: 2.5)
                .fill(NotchStyle.heatColor(level: level(for: count)))
                .frame(width: cell, height: cell)
                .help(tooltip(for: day, count: count))
        }
    }

    private func tooltip(for day: Date, count: Int) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        let films = count == 1 ? "1 film" : "\(count) films"
        return "\(df.string(from: day)) — \(films)"
    }
}

#Preview {
    ContributionHeatmapPanel(history: SampleData.history())
        .padding(16)
        .frame(width: 660, height: 150)
        .background(Color.black)
}
