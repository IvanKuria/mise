import Foundation
import MiseCore
import StatsEngine

/// Deterministic sample `WatchHistory` for previews and tests. Built from the
/// MiseUI preview films plus a few community-rated titles so the contrarian and
/// breakdown sections have something to show.
public enum DashboardSampleData {

    /// A realistic, fully-populated history (diary spread across months/years,
    /// ratings, community averages, genres, directors, cast).
    public static let history: WatchHistory = {
        WatchHistory(
            member: MemberSummary(id: "m-1", username: "cinephile", displayName: "Sam Ray"),
            diary: diary
        )
    }()

    /// Precomputed stats for the sample history.
    public static let stats: FilmStats = StatsEngine.compute(history)

    /// An empty history, for exercising the empty state.
    public static let emptyHistory = WatchHistory(
        member: MemberSummary(id: "m-0", username: "newcomer", displayName: "New Member")
    )

    // MARK: - Films

    private static func film(
        _ id: String,
        _ name: String,
        year: Int,
        runtime: Int,
        genres: [String],
        director: (String, String),
        cast: [(String, String)] = [],
        community: Double?
    ) -> Film {
        Film(
            id: id,
            name: name,
            releaseYear: year,
            runtimeMinutes: runtime,
            genres: genres.enumerated().map { Genre(id: "\(id)-g\($0.offset)", name: $0.element) },
            directors: [Person(id: director.0, name: director.1)],
            cast: cast.map { Person(id: $0.0, name: $0.1) },
            countries: ["United States"],
            languages: ["English"],
            letterboxdAverageRating: community
        )
    }

    private static let films: [Film] = [
        film("f1", "In the Mood for Love", year: 2000, runtime: 98,
             genres: ["Romance", "Drama"], director: ("d-wkw", "Wong Kar-wai"),
             cast: [("c-tony", "Tony Leung"), ("c-maggie", "Maggie Cheung")], community: 4.4),
        film("f2", "Chungking Express", year: 1994, runtime: 102,
             genres: ["Romance", "Comedy"], director: ("d-wkw", "Wong Kar-wai"),
             cast: [("c-tony", "Tony Leung")], community: 4.2),
        film("f3", "There Will Be Blood", year: 2007, runtime: 158,
             genres: ["Drama"], director: ("d-pta", "Paul Thomas Anderson"),
             cast: [("c-dday", "Daniel Day-Lewis")], community: 4.3),
        film("f4", "The Master", year: 2012, runtime: 138,
             genres: ["Drama"], director: ("d-pta", "Paul Thomas Anderson"),
             cast: [("c-phoenix", "Joaquin Phoenix")], community: 3.9),
        film("f5", "Drive", year: 2011, runtime: 100,
             genres: ["Crime", "Drama"], director: ("d-nwr", "Nicolas Winding Refn"),
             cast: [("c-gosling", "Ryan Gosling")], community: 3.8),
        film("f6", "Mandy", year: 2018, runtime: 121,
             genres: ["Horror", "Action"], director: ("d-cosmatos", "Panos Cosmatos"),
             cast: [("c-cage", "Nicolas Cage")], community: 3.6),
        film("f7", "Aftersun", year: 2022, runtime: 102,
             genres: ["Drama"], director: ("d-wells", "Charlotte Wells"),
             cast: [("c-mescal", "Paul Mescal")], community: 4.1),
        film("f8", "Past Lives", year: 2023, runtime: 105,
             genres: ["Romance", "Drama"], director: ("d-song", "Celine Song"),
             cast: [("c-lee", "Greta Lee")], community: 4.2),
        film("f9", "Blade Runner 2049", year: 2017, runtime: 164,
             genres: ["Science Fiction", "Drama"], director: ("d-villeneuve", "Denis Villeneuve"),
             cast: [("c-gosling", "Ryan Gosling")], community: 4.1),
        film("f10", "Dune", year: 2021, runtime: 155,
             genres: ["Science Fiction", "Adventure"], director: ("d-villeneuve", "Denis Villeneuve"),
             cast: [("c-chalamet", "Timothée Chalamet")], community: 3.9),
        film("f11", "Heat", year: 1995, runtime: 170,
             genres: ["Crime", "Action"], director: ("d-mann", "Michael Mann"),
             cast: [("c-pacino", "Al Pacino")], community: 4.2),
        film("f12", "Stalker", year: 1979, runtime: 162,
             genres: ["Science Fiction", "Drama"], director: ("d-tarkovsky", "Andrei Tarkovsky"),
             cast: [], community: 4.3),
    ]

    // MARK: - Diary

    /// Member ratings in half-stars, paired with the films above. Includes a few
    /// deliberate hot takes (well above / below the crowd).
    private static let memberHalfStars: [Int] = [10, 9, 9, 7, 10, 4, 9, 8, 8, 6, 9, 5]

    private static let diary: [DiaryEntry] = {
        let calendar = Calendar(identifier: .gregorian)
        return films.enumerated().map { index, film in
            // Spread watches across two years and varied months for the heatmap.
            let monthsBack = index
            let base = DateComponents(year: 2026, month: 6, day: 18)
            let watchDate = calendar.date(from: base).flatMap {
                calendar.date(byAdding: .day, value: -(monthsBack * 23), to: $0)
            }
            return DiaryEntry(
                id: "d-\(index)",
                film: film,
                watchedDate: watchDate,
                loggedDate: watchDate,
                rating: Rating(halfStars: memberHalfStars[index]),
                isRewatch: index % 5 == 0,
                isLiked: memberHalfStars[index] >= 8,
                review: index % 3 == 0 ? "A note on \(film.name)." : nil
            )
        }
    }()
}
