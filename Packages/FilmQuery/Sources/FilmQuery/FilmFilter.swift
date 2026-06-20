import Foundation
import MiseCore

/// A faceted, AND-combined filter over diary entries. Every dimension is optional;
/// a dimension that is `nil` (or empty, for set-based dimensions) imposes no
/// constraint. The empty filter (`.all`) matches everything.
public struct FilmFilter: Hashable, Sendable {
    /// Inclusive range of ratings. An entry with no rating never matches a
    /// rating constraint.
    public var ratingRange: ClosedRange<Rating>?
    /// Genre names to match. An entry matches if any of its film's genres
    /// (by name) is in this set. Empty set imposes no constraint.
    public var genres: Set<String>
    /// Decades to match (e.g. 1980). Empty set imposes no constraint.
    public var decades: Set<Int>
    /// Inclusive range of release years.
    public var yearRange: ClosedRange<Int>?
    /// If set, requires the entry's `isRewatch` to equal this value.
    public var isRewatch: Bool?
    /// If set, requires the entry's `isLiked` to equal this value.
    public var isLiked: Bool?
    /// If set, requires the entry's `hasReview` to equal this value.
    public var hasReview: Bool?
    /// Inclusive range of runtime in minutes. An entry whose film has no
    /// runtime never matches a runtime constraint.
    public var runtimeRange: ClosedRange<Int>?
    /// Inclusive range of watched dates. An entry with no `watchedDate` never
    /// matches a watched-date constraint.
    public var watchedDateRange: ClosedRange<Date>?
    /// Case- and diacritic-insensitive substring match on the film name.
    /// A `nil` or whitespace-only value imposes no constraint.
    public var freeText: String?

    public init(
        ratingRange: ClosedRange<Rating>? = nil,
        genres: Set<String> = [],
        decades: Set<Int> = [],
        yearRange: ClosedRange<Int>? = nil,
        isRewatch: Bool? = nil,
        isLiked: Bool? = nil,
        hasReview: Bool? = nil,
        runtimeRange: ClosedRange<Int>? = nil,
        watchedDateRange: ClosedRange<Date>? = nil,
        freeText: String? = nil
    ) {
        self.ratingRange = ratingRange
        self.genres = genres
        self.decades = decades
        self.yearRange = yearRange
        self.isRewatch = isRewatch
        self.isLiked = isLiked
        self.hasReview = hasReview
        self.runtimeRange = runtimeRange
        self.watchedDateRange = watchedDateRange
        self.freeText = freeText
    }

    /// The filter that matches everything.
    public static let all = FilmFilter()

    /// True when no dimension constrains the result (equivalent to `.all`).
    public var isEmpty: Bool {
        ratingRange == nil
            && genres.isEmpty
            && decades.isEmpty
            && yearRange == nil
            && isRewatch == nil
            && isLiked == nil
            && hasReview == nil
            && runtimeRange == nil
            && watchedDateRange == nil
            && normalizedFreeText == nil
    }

    /// The free-text query trimmed of surrounding whitespace, or `nil` if empty.
    var normalizedFreeText: String? {
        guard let freeText else { return nil }
        let trimmed = freeText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Convenience builder using raw half-star bounds (each 1...10). Returns the
    /// unchanged filter if either bound is out of range or `min > max`.
    public func withRatingHalfStars(min minHalf: Int, max maxHalf: Int) -> FilmFilter {
        guard
            let lower = Rating(halfStars: minHalf),
            let upper = Rating(halfStars: maxHalf),
            lower <= upper
        else { return self }
        var copy = self
        copy.ratingRange = lower...upper
        return copy
    }
}

extension FilmFilter {
    /// Whether the given entry satisfies every active dimension of this filter.
    func matches(_ entry: DiaryEntry) -> Bool {
        if let ratingRange {
            guard let rating = entry.rating, ratingRange.contains(rating) else { return false }
        }
        if !genres.isEmpty {
            let names = Set(entry.film.genres.map(\.name))
            guard !names.isDisjoint(with: genres) else { return false }
        }
        if !decades.isEmpty {
            guard let decade = entry.film.decade, decades.contains(decade) else { return false }
        }
        if let yearRange {
            guard let year = entry.film.releaseYear, yearRange.contains(year) else { return false }
        }
        if let isRewatch {
            guard entry.isRewatch == isRewatch else { return false }
        }
        if let isLiked {
            guard entry.isLiked == isLiked else { return false }
        }
        if let hasReview {
            guard entry.hasReview == hasReview else { return false }
        }
        if let runtimeRange {
            guard let runtime = entry.film.runtimeMinutes, runtimeRange.contains(runtime) else { return false }
        }
        if let watchedDateRange {
            guard let watched = entry.watchedDate, watchedDateRange.contains(watched) else { return false }
        }
        if let query = normalizedFreeText {
            guard entry.film.name.range(
                of: query,
                options: [.caseInsensitive, .diacriticInsensitive],
                range: nil,
                locale: nil
            ) != nil else { return false }
        }
        return true
    }
}
