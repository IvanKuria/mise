import Foundation

/// A Letterboxd rating, stored as half-stars (1...10) so half-star ratings are
/// represented exactly without floating-point drift. 10 == ★★★★★, 1 == ½.
public struct Rating: Hashable, Codable, Sendable, Comparable {
    /// Number of half-stars, valid range 1...10.
    public let halfStars: Int

    /// Fails if `halfStars` is outside 1...10.
    public init?(halfStars: Int) {
        guard (1...10).contains(halfStars) else { return nil }
        self.halfStars = halfStars
    }

    /// Build from a star value (e.g. 4.5). Fails if not a valid half-step in 0.5...5.0.
    public init?(stars: Double) {
        let doubled = (stars * 2).rounded()
        // Reject values that aren't exact half-steps (e.g. 4.3).
        guard abs(doubled - stars * 2) < 0.0001 else { return nil }
        self.init(halfStars: Int(doubled))
    }

    /// The rating as stars, e.g. 4.5.
    public var stars: Double {
        Double(halfStars) / 2
    }

    /// A textual star representation, e.g. "★★★★½".
    public var starString: String {
        let full = halfStars / 2
        let hasHalf = halfStars % 2 == 1
        return String(repeating: "★", count: full) + (hasHalf ? "½" : "")
    }

    public static func < (lhs: Rating, rhs: Rating) -> Bool {
        lhs.halfStars < rhs.halfStars
    }
}
