import Foundation
import MiseCore

/// Sample model values for SwiftUI previews and downstream packages' previews.
/// These are deterministic and safe to use in tests.
public enum MiseUIPreviewData {

    // MARK: Films

    public static let filmWithPoster = Film(
        id: "lb-1",
        name: "In the Mood for Love",
        releaseYear: 2000,
        runtimeMinutes: 98,
        genres: [Genre(id: "g1", name: "Romance"), Genre(id: "g2", name: "Drama")],
        directors: [Person(id: "p1", name: "Wong Kar-wai")],
        countries: ["Hong Kong"],
        tmdbID: 843,
        posterURL: URL(string: "https://image.tmdb.org/t/p/w500/iYypPT4bhqXfq1b6EnmxvRt6b2Y.jpg"),
        letterboxdAverageRating: 4.4
    )

    public static let filmNoPoster = Film(
        id: "lb-2",
        name: "Stalker",
        releaseYear: 1979,
        runtimeMinutes: 162,
        genres: [Genre(id: "g3", name: "Science Fiction")],
        directors: [Person(id: "p2", name: "Andrei Tarkovsky")],
        countries: ["Soviet Union"]
    )

    public static let filmShortTitle = Film(
        id: "lb-3",
        name: "Heat",
        releaseYear: 1995,
        directors: [Person(id: "p3", name: "Michael Mann")]
    )

    /// A spread of films for poster-wall and grid previews.
    public static let films: [Film] = {
        let names: [(String, Int)] = [
            ("Mulholland Drive", 2001),
            ("Paris, Texas", 1984),
            ("Chungking Express", 1994),
            ("The Master", 2012),
            ("Burning", 2018),
            ("Portrait of a Lady on Fire", 2019),
            ("Drive My Car", 2021),
            ("Aftersun", 2022),
            ("Past Lives", 2023),
            ("Perfect Days", 2023),
        ]
        var result = [filmWithPoster, filmNoPoster, filmShortTitle]
        for (i, n) in names.enumerated() {
            result.append(Film(id: "lb-\(100 + i)", name: n.0, releaseYear: n.1))
        }
        return result
    }()

    // MARK: Diary

    public static let diaryEntry = DiaryEntry(
        id: "d-1",
        film: filmWithPoster,
        watchedDate: DateComponents(calendar: .current, year: 2026, month: 6, day: 14).date,
        loggedDate: DateComponents(calendar: .current, year: 2026, month: 6, day: 14).date,
        rating: Rating(halfStars: 9),
        isRewatch: true,
        isLiked: true,
        review: "Still the most beautiful film about restraint.",
        tags: ["rewatch", "favorite"]
    )

    public static let diary: [DiaryEntry] = {
        let ratings = [10, 8, 7, 9, 6, 8, 5]
        return films.enumerated().map { i, film in
            DiaryEntry(
                id: "d-\(i)",
                film: film,
                watchedDate: DateComponents(
                    calendar: .current, year: 2026, month: 6, day: (i % 28) + 1
                ).date,
                rating: Rating(halfStars: ratings[i % ratings.count]),
                isRewatch: i % 4 == 0,
                isLiked: i % 3 == 0
            )
        }
    }()

    // MARK: Heatmap

    /// A year of synthetic activity counts for heatmap previews.
    public static let heatmapCounts: [DayKey: Int] = {
        var dict: [DayKey: Int] = [:]
        let calendar = Calendar(identifier: .gregorian)
        guard let start = calendar.date(from: DateComponents(year: 2025, month: 7, day: 1)) else {
            return dict
        }
        for offset in 0..<360 {
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else { continue }
            // Deterministic pseudo-random density.
            let pseudo = (offset * 2654435761) % 97
            let count: Int
            switch pseudo {
            case 0..<55: count = 0
            case 55..<75: count = 1
            case 75..<88: count = 2
            case 88..<95: count = 3
            default:      count = 5
            }
            if count > 0 {
                dict[DayKey(date: date, calendar: calendar)] = count
            }
        }
        return dict
    }()
}
