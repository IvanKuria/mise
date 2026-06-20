import Foundation
import MiseCore

/// A recommended film the target hasn't logged, scored from the tastes of
/// similar members.
public struct Recommendation: Hashable, Sendable {
    public let film: Film
    /// Higher means a stronger recommendation. Sum over supporting members of
    /// `similarity(target, member) * (rating.stars - 3.0)`.
    public let score: Double
    /// How many members contributed to this recommendation.
    public let supportingMemberCount: Int

    public init(film: Film, score: Double, supportingMemberCount: Int) {
        self.film = film
        self.score = score
        self.supportingMemberCount = supportingMemberCount
    }
}

public func recommendations(
    for target: WatchHistory,
    from others: [WatchHistory],
    limit: Int,
    minimumSharedFilms: Int = 3
) -> [Recommendation] {
    guard limit > 0 else { return [] }

    let targetSeen = Set(target.diary.map { $0.film.id })

    // Accumulate per candidate film.
    var scores: [String: Double] = [:]
    var counts: [String: Int] = [:]
    var films: [String: Film] = [:]

    for other in others {
        let similarity = tasteSimilarity(target, other, minimumSharedFilms: minimumSharedFilms)
        guard similarity > 0 else { continue }

        for entry in other.diary {
            guard let rating = entry.rating, rating.stars >= 4.0 else { continue }
            let id = entry.film.id
            guard !targetSeen.contains(id) else { continue }

            scores[id, default: 0] += similarity * (rating.stars - 3.0)
            counts[id, default: 0] += 1
            films[id] = entry.film
        }
    }

    let ranked = scores.keys.sorted { lhs, rhs in
        let sl = scores[lhs]!
        let sr = scores[rhs]!
        if sl != sr { return sl > sr }
        return lhs < rhs // deterministic tie-break by film id
    }

    return ranked.prefix(limit).map { id in
        Recommendation(
            film: films[id]!,
            score: scores[id]!,
            supportingMemberCount: counts[id]!
        )
    }
}
