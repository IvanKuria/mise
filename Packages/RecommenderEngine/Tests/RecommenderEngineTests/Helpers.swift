import Foundation
import MiseCore

/// Test fixtures and builders. Keeps the test bodies focused on behaviour.
enum Fixtures {
    static func film(_ id: String, name: String? = nil, year: Int? = nil) -> Film {
        Film(id: id, name: name ?? "Film \(id)", releaseYear: year)
    }

    static func member(_ id: String) -> MemberSummary {
        MemberSummary(id: id, username: id, displayName: id)
    }

    /// A diary entry for `film` with the given star rating (nil == logged, no rating).
    static func entry(_ film: Film, stars: Double?) -> DiaryEntry {
        let rating = stars.flatMap { Rating(stars: $0) }
        return DiaryEntry(id: "entry-\(film.id)", film: film, rating: rating)
    }

    /// A WatchHistory from (filmID, stars?) pairs. Films are created on the fly.
    static func history(
        _ memberID: String,
        _ ratings: [(String, Double?)]
    ) -> WatchHistory {
        let diary = ratings.map { entry(film($0.0), stars: $0.1) }
        return WatchHistory(member: member(memberID), diary: diary)
    }
}
