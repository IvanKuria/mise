import SwiftUI
import MiseCore

/// "On this day" — films logged on today's month+day across prior years, newest
/// first. Tapping a film runs a matched-geometry transition into a
/// `FilmDetailView`. Renders on the black notch panel (clear background).
struct OnThisDayPanel: View {
    let history: WatchHistory

    init(history: WatchHistory) { self.history = history }

    @Namespace private var ns
    @State private var selected: DiaryEntry?

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
        Group {
            if let sel = selected {
                FilmDetailView(entry: sel, namespace: ns, onClose: back)
            } else {
                strip
            }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.82), value: selected?.id)
    }

    @ViewBuilder
    private var strip: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(todayLabel)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(NotchStyle.textTertiary)

            if entries.isEmpty {
                EmptyHint(symbol: "calendar", text: "Nothing logged on this day — yet.")
            } else {
                HStack(alignment: .top, spacing: 16) {
                    ForEach(entries.prefix(7)) { entry in
                        cell(entry)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private func cell(_ entry: DiaryEntry) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            FilmPoster(film: entry.film, width: NotchStyle.posterWidth)
                .matchedGeometryEffect(id: entry.id, in: ns)
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.film.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(NotchStyle.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 5) {
                    if let year = entry.film.releaseYear {
                        Text(String(year))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(NotchStyle.textSecondary)
                    }
                    if let rating = entry.rating {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 7, weight: .semibold))
                                .foregroundStyle(NotchStyle.star)
                            Text(String(format: "%g", rating.stars))
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(NotchStyle.textSecondary)
                        }
                    }
                    if entry.isLiked {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(NotchStyle.heart)
                    }
                }
            }
            .frame(width: NotchStyle.posterWidth, alignment: .leading)
        }
        .contentShape(Rectangle())
        .onTapGesture { withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) { selected = entry } }
        .help(entry.film.name + (entry.film.releaseYear.map { " (\($0))" } ?? ""))
    }

    private func back() {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) { selected = nil }
    }
}

#Preview {
    OnThisDayPanel(history: SampleData.history())
        .environment(AppState())
        .padding(20)
        .frame(width: 720, height: 220)
        .background(Color.black)
}
