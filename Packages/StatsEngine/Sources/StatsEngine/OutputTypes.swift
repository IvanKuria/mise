import Foundation
import MiseCore

/// Aggregate count + average-rating pair for a bucket (genre, decade, person, ...).
public struct CountAverage: Hashable, Sendable {
    public let count: Int
    /// Mean of member ratings (in stars) over the rated entries in this bucket;
    /// `nil` when no entry in the bucket carries a rating.
    public let averageRating: Double?

    public init(count: Int, averageRating: Double?) {
        self.count = count
        self.averageRating = averageRating
    }
}

/// A named bucket with its aggregate, used for ordered breakdowns (directors, cast).
public struct NamedAggregate: Hashable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let count: Int
    public let averageRating: Double?

    public init(id: String, name: String, count: Int, averageRating: Double?) {
        self.id = id
        self.name = name
        self.count = count
        self.averageRating = averageRating
    }
}

/// A film whose member rating deviates from the Letterboxd community average.
public struct FilmTakeDelta: Hashable, Sendable, Identifiable {
    public var id: String { filmID }
    public let filmID: String
    public let filmName: String
    /// Member rating in stars.
    public let memberStars: Double
    /// Letterboxd community average in stars.
    public let communityStars: Double
    /// memberStars - communityStars. Positive: liked more than the crowd.
    public let delta: Double

    public init(filmID: String, filmName: String, memberStars: Double, communityStars: Double) {
        self.filmID = filmID
        self.filmName = filmName
        self.memberStars = memberStars
        self.communityStars = communityStars
        self.delta = memberStars - communityStars
    }
}

/// A single calendar day, used as a stable heatmap key.
public struct DayKey: Hashable, Sendable, Comparable, Codable {
    public let year: Int
    public let month: Int
    public let day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    public static func < (lhs: DayKey, rhs: DayKey) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }
}

/// A calendar year + month, used as a stable monthly time-series key.
public struct MonthKey: Hashable, Sendable, Comparable, Codable {
    public let year: Int
    public let month: Int

    public init(year: Int, month: Int) {
        self.year = year
        self.month = month
    }

    public static func < (lhs: MonthKey, rhs: MonthKey) -> Bool {
        (lhs.year, lhs.month) < (rhs.year, rhs.month)
    }
}

/// The full analytics result for a member's watch history. Pure value type.
public struct FilmStats: Hashable, Sendable {
    // Counts
    public let totalLogged: Int
    public let rewatchCount: Int
    public let likedCount: Int
    public let reviewCount: Int
    public let distinctFilmCount: Int

    // Ratings
    /// half-stars (1...10) -> count, from rated diary entries.
    public let ratingsHistogram: [Int: Int]

    // Contrarian
    /// Mean of (memberStars - communityStars) over rated films with a known
    /// Letterboxd average. `nil` when there are no such films.
    public let contrarianScore: Double?
    /// Films with the largest absolute deviation, sorted by |delta| descending.
    public let hottestTakes: [FilmTakeDelta]

    // Breakdowns
    public let genreBreakdown: [String: CountAverage]
    public let decadeBreakdown: [Int: CountAverage]
    public let countryBreakdown: [String: CountAverage]
    public let languageBreakdown: [String: CountAverage]

    // People
    public let topDirectors: [NamedAggregate]
    public let topCast: [NamedAggregate]

    // Runtime
    public let totalRuntimeMinutes: Int
    /// calendar year -> minutes watched.
    public let runtimeMinutesPerYear: [Int: Int]

    // Heatmap / streaks
    public let heatmap: [DayKey: Int]
    public let longestStreakDays: Int
    /// Consecutive days ending at the most recent watch date (deterministic).
    public let currentStreakDays: Int

    // Time series
    public let filmsPerYear: [Int: Int]
    public let filmsPerMonth: [MonthKey: Int]

    public init(
        totalLogged: Int,
        rewatchCount: Int,
        likedCount: Int,
        reviewCount: Int,
        distinctFilmCount: Int,
        ratingsHistogram: [Int: Int],
        contrarianScore: Double?,
        hottestTakes: [FilmTakeDelta],
        genreBreakdown: [String: CountAverage],
        decadeBreakdown: [Int: CountAverage],
        countryBreakdown: [String: CountAverage],
        languageBreakdown: [String: CountAverage],
        topDirectors: [NamedAggregate],
        topCast: [NamedAggregate],
        totalRuntimeMinutes: Int,
        runtimeMinutesPerYear: [Int: Int],
        heatmap: [DayKey: Int],
        longestStreakDays: Int,
        currentStreakDays: Int,
        filmsPerYear: [Int: Int],
        filmsPerMonth: [MonthKey: Int]
    ) {
        self.totalLogged = totalLogged
        self.rewatchCount = rewatchCount
        self.likedCount = likedCount
        self.reviewCount = reviewCount
        self.distinctFilmCount = distinctFilmCount
        self.ratingsHistogram = ratingsHistogram
        self.contrarianScore = contrarianScore
        self.hottestTakes = hottestTakes
        self.genreBreakdown = genreBreakdown
        self.decadeBreakdown = decadeBreakdown
        self.countryBreakdown = countryBreakdown
        self.languageBreakdown = languageBreakdown
        self.topDirectors = topDirectors
        self.topCast = topCast
        self.totalRuntimeMinutes = totalRuntimeMinutes
        self.runtimeMinutesPerYear = runtimeMinutesPerYear
        self.heatmap = heatmap
        self.longestStreakDays = longestStreakDays
        self.currentStreakDays = currentStreakDays
        self.filmsPerYear = filmsPerYear
        self.filmsPerMonth = filmsPerMonth
    }
}

/// Tuning knobs for the analytics computation.
public struct StatsOptions: Hashable, Sendable {
    /// Minimum appearances for a director to be included in `topDirectors`.
    public let minDirectorCount: Int
    /// Minimum appearances for a cast member to be included in `topCast`.
    public let minCastCount: Int
    /// Maximum number of hottest takes to return.
    public let maxHottestTakes: Int

    public init(
        minDirectorCount: Int = 1,
        minCastCount: Int = 2,
        maxHottestTakes: Int = 10
    ) {
        self.minDirectorCount = minDirectorCount
        self.minCastCount = minCastCount
        self.maxHottestTakes = maxHottestTakes
    }

    public static let `default` = StatsOptions()
}
