import SwiftUI
import MiseCore

/// A compact filmstrip of the most recent diary entries, rendered inside the
/// expanded black notch panel. No opaque background of its own — it sits on the
/// notch's black surface and leans on `NotchStyle` tokens for color.
struct RecentlyWatchedPanel: View {
    let history: WatchHistory

    init(history: WatchHistory) {
        self.history = history
    }

    /// Last ~6 entries, newest first, one per film.
    private var entries: [DiaryEntry] {
        var seen = Set<String>()
        return history.diary
            .sorted { lhs, rhs in
                let l = lhs.watchedDate ?? lhs.loggedDate ?? .distantPast
                let r = rhs.watchedDate ?? rhs.loggedDate ?? .distantPast
                return l > r
            }
            .filter { seen.insert($0.film.id).inserted }
            .prefix(6)
            .map { $0 }
    }

    var body: some View {
        Group {
            if entries.isEmpty {
                emptyState
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 14) {
                        ForEach(entries) { entry in
                            FilmCell(entry: entry)
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        Text("No films logged yet")
            .font(.system(size: 12))
            .foregroundStyle(NotchStyle.textTertiary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct FilmCell: View {
    let entry: DiaryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            FilmPoster(film: entry.film, width: 54)

            Text(entry.film.name)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(NotchStyle.textPrimary)
                .lineLimit(1)
                .frame(width: 54, alignment: .leading)

            HStack(spacing: 3) {
                if let stars = entry.rating?.starString {
                    Text(stars)
                        .font(.system(size: 9))
                        .foregroundStyle(NotchStyle.green)
                        .lineLimit(1)
                }
                if entry.isLiked {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(NotchStyle.heartRed)
                }
            }
            .frame(width: 54, alignment: .leading)
        }
    }
}

#Preview {
    RecentlyWatchedPanel(history: SampleData.history())
        .padding(NotchStyle.spacing)
        .frame(width: 660, height: 150)
        .background(NotchStyle.panel)
}
