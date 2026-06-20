import Foundation
import MiseCore

/// Pure, deterministic "Tonight's Pick" solver over a watchlist. No I/O, no UI.
public enum WatchlistPlanner {

    /// Filter the watchlist to the films meeting every criterion (AND across
    /// dimensions). Preserves input order.
    public static func candidates(
        _ watchlist: [WatchlistItem],
        availability: StreamingAvailability,
        criteria: TonightCriteria
    ) -> [WatchlistItem] {
        watchlist.filter { matches($0, availability: availability, criteria: criteria) }
    }

    /// Apply `candidates`, then choose one per `ranking`. Returns `nil` when no
    /// candidate remains.
    public static func pick(
        _ watchlist: [WatchlistItem],
        availability: StreamingAvailability,
        criteria: TonightCriteria,
        ranking: Ranking
    ) -> WatchlistItem? {
        let pool = candidates(watchlist, availability: availability, criteria: criteria)
        guard !pool.isEmpty else { return nil }

        switch ranking {
        case .shortestFirst:
            return pool.min(by: shortestFirstOrder)
        case .highestRated:
            return pool.min(by: highestRatedOrder)
        case .random(let seed):
            return pool.seededShuffled(seed: seed).first
        }
    }

    /// A deterministic seeded ordering of the candidates.
    public static func shuffle(
        _ watchlist: [WatchlistItem],
        availability: StreamingAvailability,
        criteria: TonightCriteria,
        seed: UInt64
    ) -> [WatchlistItem] {
        candidates(watchlist, availability: availability, criteria: criteria)
            .seededShuffled(seed: seed)
    }

    // MARK: - Filtering

    private static func matches(
        _ item: WatchlistItem,
        availability: StreamingAvailability,
        criteria: TonightCriteria
    ) -> Bool {
        let film = item.film

        if let cap = criteria.maxRuntimeMinutes {
            guard let runtime = film.runtimeMinutes, runtime <= cap else { return false }
        }

        if !criteria.requiredServices.isEmpty {
            let have = availability.services(for: film.id)
            guard !have.isDisjoint(with: criteria.requiredServices) else { return false }
        }

        if !criteria.genres.isEmpty {
            let wanted = Set(criteria.genres.map { $0.lowercased() })
            let filmGenres = Set(film.genres.map { $0.name.lowercased() })
            guard !filmGenres.isDisjoint(with: wanted) else { return false }
        }

        if let minAvg = criteria.minLetterboxdAverage {
            guard let avg = film.letterboxdAverageRating, avg >= minAvg else { return false }
        }

        return true
    }

    // MARK: - Ordering

    /// `true` if `a` should come before `b` for shortestFirst.
    /// Shorter runtime, then higher average, then lexicographic id.
    private static func shortestFirstOrder(_ a: WatchlistItem, _ b: WatchlistItem) -> Bool {
        let ra = a.film.runtimeMinutes ?? .max
        let rb = b.film.runtimeMinutes ?? .max
        if ra != rb { return ra < rb }

        let aa = a.film.letterboxdAverageRating ?? -.infinity
        let ab = b.film.letterboxdAverageRating ?? -.infinity
        if aa != ab { return aa > ab }

        return a.id < b.id
    }

    /// `true` if `a` should come before `b` for highestRated.
    /// Higher average, then shorter runtime, then lexicographic id.
    private static func highestRatedOrder(_ a: WatchlistItem, _ b: WatchlistItem) -> Bool {
        let aa = a.film.letterboxdAverageRating ?? -.infinity
        let ab = b.film.letterboxdAverageRating ?? -.infinity
        if aa != ab { return aa > ab }

        let ra = a.film.runtimeMinutes ?? .max
        let rb = b.film.runtimeMinutes ?? .max
        if ra != rb { return ra < rb }

        return a.id < b.id
    }
}
