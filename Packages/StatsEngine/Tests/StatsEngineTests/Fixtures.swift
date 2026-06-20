import Foundation
import MiseCore

/// Test helpers for building `WatchHistory` fixtures.
enum Fixtures {
    static let member = MemberSummary(
        id: "m1",
        username: "tester",
        displayName: "Tester"
    )

    /// Parse an ISO-ish "yyyy-MM-dd" date in UTC. Force-unwrapped: test-only.
    static func date(_ s: String) -> Date {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: s)!
    }

    static func rating(_ stars: Double) -> Rating {
        Rating(stars: stars)!
    }

    static func genre(_ name: String) -> Genre {
        Genre(id: name.lowercased(), name: name)
    }

    static func person(_ name: String) -> Person {
        Person(id: name.lowercased().replacingOccurrences(of: " ", with: "-"), name: name)
    }

    static func film(
        id: String,
        name: String? = nil,
        year: Int? = nil,
        runtime: Int? = nil,
        genres: [Genre] = [],
        directors: [Person] = [],
        cast: [Person] = [],
        countries: [String] = [],
        languages: [String] = [],
        lbAvg: Double? = nil
    ) -> Film {
        Film(
            id: id,
            name: name ?? id,
            releaseYear: year,
            runtimeMinutes: runtime,
            genres: genres,
            directors: directors,
            cast: cast,
            countries: countries,
            languages: languages,
            letterboxdAverageRating: lbAvg
        )
    }

    static func entry(
        id: String,
        film: Film,
        watched: String? = nil,
        rating: Rating? = nil,
        isRewatch: Bool = false,
        isLiked: Bool = false,
        review: String? = nil
    ) -> DiaryEntry {
        DiaryEntry(
            id: id,
            film: film,
            watchedDate: watched.map(date),
            rating: rating,
            isRewatch: isRewatch,
            isLiked: isLiked,
            review: review
        )
    }

    static func history(_ diary: [DiaryEntry]) -> WatchHistory {
        WatchHistory(member: member, diary: diary)
    }
}
