import Foundation
import MiseCore

/// A shared film both members rated, with each member's rating, surfaced when
/// the two disagree the most.
public struct RatingDisagreement: Hashable, Sendable {
    public let film: Film
    /// First member's rating (the `a` argument of `compare`).
    public let ratingA: Rating
    /// Second member's rating (the `b` argument of `compare`).
    public let ratingB: Rating

    public init(film: Film, ratingA: Rating, ratingB: Rating) {
        self.film = film
        self.ratingA = ratingA
        self.ratingB = ratingB
    }

    /// Absolute difference between the two ratings, in stars.
    public var delta: Double {
        abs(ratingA.stars - ratingB.stars)
    }
}

/// The result of comparing two members' watch histories.
public struct MemberComparison: Hashable, Sendable {
    /// Number of films both members rated (matched by `Film.id`).
    public let sharedFilmCount: Int
    /// Taste similarity over the shared rated films (see `tasteSimilarity`).
    public let similarity: Double
    /// Shared rated films sorted by largest rating gap first.
    public let biggestDisagreements: [RatingDisagreement]
    /// Films `a` rated >= 4.5 that `b` has no diary entry for — seeds for `b`.
    public let aLovedBHasntSeen: [Film]
    /// Films `b` rated >= 4.5 that `a` has no diary entry for — seeds for `a`.
    public let bLovedAHasntSeen: [Film]

    public init(
        sharedFilmCount: Int,
        similarity: Double,
        biggestDisagreements: [RatingDisagreement],
        aLovedBHasntSeen: [Film],
        bLovedAHasntSeen: [Film]
    ) {
        self.sharedFilmCount = sharedFilmCount
        self.similarity = similarity
        self.biggestDisagreements = biggestDisagreements
        self.aLovedBHasntSeen = aLovedBHasntSeen
        self.bLovedAHasntSeen = bLovedAHasntSeen
    }
}

public func compare(
    _ a: WatchHistory,
    _ b: WatchHistory,
    minimumSharedFilms: Int = 3
) -> MemberComparison {
    let ratingsA = ratingValuesByFilmID(a)
    let ratingsB = ratingValuesByFilmID(b)

    // Shared rated films, deterministic by film id.
    let sharedIDs = ratingsA.keys.filter { ratingsB.keys.contains($0) }.sorted()

    let disagreements: [RatingDisagreement] = sharedIDs.map { id in
        let (filmA, ratingA) = ratingsA[id]!
        let (_, ratingB) = ratingsB[id]!
        return RatingDisagreement(film: filmA, ratingA: ratingA, ratingB: ratingB)
    }
    // Largest gap first; ties broken by film id for determinism.
    .sorted { lhs, rhs in
        if lhs.delta != rhs.delta { return lhs.delta > rhs.delta }
        return lhs.film.id < rhs.film.id
    }

    // Diary presence by film id (any entry, rated or not).
    let seenByA = Set(a.diary.map { $0.film.id })
    let seenByB = Set(b.diary.map { $0.film.id })

    let aLovedBHasntSeen = lovedFilmsUnseenBy(loverRatings: ratingsA, seenByOther: seenByB)
    let bLovedAHasntSeen = lovedFilmsUnseenBy(loverRatings: ratingsB, seenByOther: seenByA)

    return MemberComparison(
        sharedFilmCount: sharedIDs.count,
        similarity: tasteSimilarity(a, b, minimumSharedFilms: minimumSharedFilms),
        biggestDisagreements: disagreements,
        aLovedBHasntSeen: aLovedBHasntSeen,
        bLovedAHasntSeen: bLovedAHasntSeen
    )
}

/// Maps `Film.id` -> (film, rating) for every rated diary entry. Last rated
/// entry for a given film wins (diary order preserved).
private func ratingValuesByFilmID(_ history: WatchHistory) -> [String: (Film, Rating)] {
    var result: [String: (Film, Rating)] = [:]
    for entry in history.diary {
        guard let rating = entry.rating else { continue }
        result[entry.film.id] = (entry.film, rating)
    }
    return result
}

/// Films the lover rated >= 4.5 stars that `seenByOther` does not contain,
/// sorted by film id for determinism.
private func lovedFilmsUnseenBy(
    loverRatings: [String: (Film, Rating)],
    seenByOther: Set<String>
) -> [Film] {
    loverRatings.values
        .filter { $0.1.stars >= 4.5 && !seenByOther.contains($0.0.id) }
        .map { $0.0 }
        .sorted { $0.id < $1.id }
}
