import Foundation
import MiseCore

/// Test fixtures. Keeps test bodies focused on behaviour.
enum Fixtures {
    static func genre(_ name: String) -> Genre {
        Genre(id: name.lowercased(), name: name)
    }

    static func film(
        _ id: String,
        runtime: Int? = nil,
        genres: [String] = [],
        avg: Double? = nil
    ) -> Film {
        Film(
            id: id,
            name: "Film \(id)",
            runtimeMinutes: runtime,
            genres: genres.map(genre),
            letterboxdAverageRating: avg
        )
    }

    static func item(
        _ id: String,
        runtime: Int? = nil,
        genres: [String] = [],
        avg: Double? = nil
    ) -> WatchlistItem {
        WatchlistItem(film: film(id, runtime: runtime, genres: genres, avg: avg))
    }
}
