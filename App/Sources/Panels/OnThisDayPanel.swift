import SwiftUI
import MiseCore

/// "On this day" — diary entries watched on today's month+day across prior
/// years, newest first. Renders on the black notch panel, so it draws no opaque
/// background of its own and uses `NotchStyle` tokens for color.
struct OnThisDayPanel: View {
    let history: WatchHistory

    init(history: WatchHistory) {
        self.history = history
    }

    private var today: DateComponents {
        Calendar.current.dateComponents([.month, .day], from: Date())
    }

    /// Entries whose watchedDate falls on today's month/day, sorted by year desc.
    private var entries: [DiaryEntry] {
        let cal = Calendar.current
        let now = today
        return history.diary
            .compactMap { entry -> (DiaryEntry, Int)? in
                guard let date = entry.watchedDate else { return nil }
                let comps = cal.dateComponents([.month, .day, .year], from: date)
                guard comps.month == now.month, comps.day == now.day,
                      let year = comps.year else { return nil }
                return (entry, year)
            }
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
    }

    private var dateLabel: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return fmt.string(from: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("On this day")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(NotchStyle.textPrimary)
                Text(dateLabel)
                    .font(.system(size: 11))
                    .foregroundStyle(NotchStyle.textTertiary)
            }

            if entries.isEmpty {
                emptyState
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 14) {
                        ForEach(entries) { entry in
                            OnThisDayCell(entry: entry)
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var emptyState: some View {
        HStack(spacing: 6) {
            Image(systemName: "calendar")
                .font(.system(size: 11))
                .foregroundStyle(NotchStyle.textTertiary)
            Text("Nothing logged on this day — yet.")
                .font(.system(size: 12))
                .foregroundStyle(NotchStyle.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

private struct OnThisDayCell: View {
    let entry: DiaryEntry

    private var year: String {
        guard let date = entry.watchedDate else { return "" }
        return String(Calendar.current.component(.year, from: date))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            FilmPoster(film: entry.film, width: 54)

            Text(year)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(NotchStyle.accent)
                .frame(width: 54, alignment: .leading)

            Text(entry.film.name)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(NotchStyle.textPrimary)
                .lineLimit(1)
                .frame(width: 54, alignment: .leading)

            if let stars = entry.rating?.starString {
                Text(stars)
                    .font(.system(size: 9))
                    .foregroundStyle(NotchStyle.green)
                    .lineLimit(1)
                    .frame(width: 54, alignment: .leading)
            }
        }
    }
}

#Preview("On this day") {
    OnThisDayPanel(history: SampleData.history())
        .padding(NotchStyle.spacing)
        .frame(width: 660, height: 150)
        .background(NotchStyle.panel)
}

#Preview("On this day — faked match") {
    // Force a match by re-stamping the first diary entry's watchedDate to today.
    var faked = SampleData.history()
    if let first = faked.diary.first {
        let stamped = DiaryEntry(
            id: first.id, film: first.film,
            watchedDate: Calendar.current.date(byAdding: .year, value: -2, to: Date()),
            loggedDate: first.loggedDate, rating: first.rating,
            isRewatch: first.isRewatch, isLiked: first.isLiked,
            review: first.review, tags: []
        )
        faked = WatchHistory(
            member: faked.member, diary: [stamped] + faked.diary.dropFirst(),
            watchlist: faked.watchlist, lists: [], statistics: faked.statistics
        )
    }
    return OnThisDayPanel(history: faked)
        .padding(NotchStyle.spacing)
        .frame(width: 660, height: 150)
        .background(NotchStyle.panel)
}
