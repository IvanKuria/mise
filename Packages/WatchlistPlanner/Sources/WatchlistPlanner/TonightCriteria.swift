import Foundation

/// The constraints used to narrow a watchlist to tonight's candidates. Each
/// dimension is optional/empty-tolerant; constraints compose with AND. Set-based
/// constraints use match-any semantics (empty == "any").
public struct TonightCriteria: Hashable, Sendable {
    /// Maximum runtime in minutes. Films with unknown runtime are excluded when set.
    public let maxRuntimeMinutes: Int?
    /// Match-any set of service names; empty means availability is ignored.
    public let requiredServices: Set<String>
    /// Match-any set of genre names (case-insensitive); empty means any genre.
    public let genres: Set<String>
    /// Minimum Letterboxd community average (stars). Unknown-rated films are excluded when set.
    public let minLetterboxdAverage: Double?

    public init(
        maxRuntimeMinutes: Int? = nil,
        requiredServices: Set<String> = [],
        genres: Set<String> = [],
        minLetterboxdAverage: Double? = nil
    ) {
        self.maxRuntimeMinutes = maxRuntimeMinutes
        self.requiredServices = requiredServices
        self.genres = genres
        self.minLetterboxdAverage = minLetterboxdAverage
    }
}

/// How to choose among the candidates.
public enum Ranking: Hashable, Sendable {
    /// Deterministic seeded random selection/ordering.
    case random(seed: UInt64)
    /// Shortest runtime first (tie: higher average, then id).
    case shortestFirst
    /// Highest Letterboxd average first (tie: shorter runtime, then id).
    case highestRated
}
