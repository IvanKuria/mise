import SwiftUI
import MiseCore

/// "On this day" — films logged on today's month+day across prior years, newest
/// first. Renders on the black notch panel (clear background).
struct OnThisDayPanel: View {
    let history: WatchHistory

    init(history: WatchHistory) { self.history = history }

    private var todayLabel: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM d"
        return f.string(from: Date())
    }

    private var entries: [DiaryEntry] {
        let cal = Calendar.current
        let today = cal.dateComponents([.month, .day], from: Date())
        return history.diary
            .filter { entry in
                guard let date = entry.watchedDate else { return false }
                let c = cal.dateComponents([.month, .day], from: date)
                return c.month == today.month && c.day == today.day
            }
            .sorted { ($0.watchedDate ?? .distantPast) > ($1.watchedDate ?? .distantPast) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(todayLabel)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(NotchStyle.textTertiary)

            if entries.isEmpty {
                EmptyHint(symbol: "calendar", text: "Nothing logged on this day — yet.")
            } else {
                HStack(alignment: .top, spacing: 16) {
                    ForEach(entries.prefix(7)) { entry in
                        FilmCell(entry: entry, showYear: true)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }
}

#Preview {
    OnThisDayPanel(history: SampleData.history())
        .padding(20)
        .frame(width: 720, height: 220)
        .background(Color.black)
}
