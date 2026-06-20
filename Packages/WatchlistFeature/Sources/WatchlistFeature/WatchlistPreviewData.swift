import Foundation
import MiseCore
import WatchlistPlanner

/// Deterministic sample data for previews and tests of the watchlist feature.
public enum WatchlistPreviewData {

    public static let watchlist: [WatchlistItem] = films.map {
        WatchlistItem(film: $0, addedDate: nil)
    }

    public static let films: [Film] = [
        film(
            id: "w-1", name: "In the Mood for Love", year: 2000, runtime: 98,
            genres: ["Romance", "Drama"], avg: 4.4,
            poster: "https://image.tmdb.org/t/p/w500/iYypPT4bhqXfq1b6EnmxvRt6b2Y.jpg"
        ),
        film(id: "w-2", name: "Stalker", year: 1979, runtime: 162,
             genres: ["Science Fiction", "Drama"], avg: 4.3),
        film(id: "w-3", name: "Heat", year: 1995, runtime: 170,
             genres: ["Crime", "Thriller"], avg: 4.2),
        film(id: "w-4", name: "Chungking Express", year: 1994, runtime: 102,
             genres: ["Romance", "Comedy"], avg: 4.1),
        film(id: "w-5", name: "Aftersun", year: 2022, runtime: 102,
             genres: ["Drama"], avg: 4.0),
        film(id: "w-6", name: "Paddington 2", year: 2017, runtime: 103,
             genres: ["Comedy", "Family"], avg: 4.0),
        film(id: "w-7", name: "Burning", year: 2018, runtime: 148,
             genres: ["Drama", "Thriller"], avg: 3.9),
        film(id: "w-8", name: "Portrait of a Lady on Fire", year: 2019, runtime: 122,
             genres: ["Romance", "Drama"], avg: 4.3),
        film(id: "w-9", name: "The Lighthouse", year: 2019, runtime: 109,
             genres: ["Horror", "Drama"], avg: 3.8),
        film(id: "w-10", name: "Past Lives", year: 2023, runtime: 105,
             genres: ["Romance", "Drama"], avg: 4.1),
    ]

    /// A few films marked as streaming on common services.
    public static let availability = StreamingAvailability(byFilmID: [
        "w-1": ["Max", "Criterion"],
        "w-4": ["Criterion"],
        "w-5": ["Mubi"],
        "w-6": ["Netflix"],
        "w-8": ["Hulu", "Criterion"],
        "w-10": ["Netflix"],
    ])

    // MARK: Helpers

    private static func film(
        id: String,
        name: String,
        year: Int,
        runtime: Int,
        genres: [String],
        avg: Double,
        poster: String? = nil
    ) -> Film {
        Film(
            id: id,
            name: name,
            releaseYear: year,
            runtimeMinutes: runtime,
            genres: genres.enumerated().map { Genre(id: "\(id)-g\($0.offset)", name: $0.element) },
            posterURL: poster.flatMap(URL.init(string:)),
            letterboxdAverageRating: avg
        )
    }
}
