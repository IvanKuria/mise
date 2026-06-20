import Foundation
import MiseCore

/// Test helpers for building films and diary entries concisely.
enum Fixtures {
    static func rating(_ halfStars: Int) -> Rating {
        Rating(halfStars: halfStars)!
    }

    static func genres(_ names: [String]) -> [Genre] {
        names.map { Genre(id: $0.lowercased(), name: $0) }
    }

    static func film(
        id: String,
        name: String,
        year: Int? = nil,
        runtime: Int? = nil,
        genres genreNames: [String] = []
    ) -> Film {
        Film(
            id: id,
            name: name,
            releaseYear: year,
            runtimeMinutes: runtime,
            genres: genres(genreNames)
        )
    }

    /// A date `daysFromEpoch` days after 2000-01-01 UTC (stable, deterministic).
    static func date(_ daysFromEpoch: Int) -> Date {
        let base = Date(timeIntervalSince1970: 946_684_800) // 2000-01-01T00:00:00Z
        return base.addingTimeInterval(TimeInterval(daysFromEpoch) * 86_400)
    }

    static func entry(
        id: String,
        film: Film,
        watched: Date? = nil,
        rating: Rating? = nil,
        isRewatch: Bool = false,
        isLiked: Bool = false,
        review: String? = nil
    ) -> DiaryEntry {
        DiaryEntry(
            id: id,
            film: film,
            watchedDate: watched,
            rating: rating,
            isRewatch: isRewatch,
            isLiked: isLiked,
            review: review
        )
    }
}
