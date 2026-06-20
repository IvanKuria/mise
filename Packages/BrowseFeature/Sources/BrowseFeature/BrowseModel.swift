import Foundation
import Observation
import MiseCore
import FilmQuery

/// The observable state for the offline power-browser. Holds the source diary,
/// the active `FilmFilter` and `FilmSort`, and derives the available `Facets`
/// (from the *unfiltered* source so controls never disappear) plus the filtered,
/// sorted `results`. All query work delegates to the pure `FilmQuery` engine.
@MainActor
@Observable
public final class BrowseModel {
    /// The full, unfiltered source of diary entries the browser operates over.
    public private(set) var entries: [DiaryEntry]

    /// The active filter. Mutating it re-derives `results`.
    public var filter: FilmFilter

    /// The active sort order. Mutating it re-orders `results`.
    public var sort: FilmSort

    public init(
        entries: [DiaryEntry],
        filter: FilmFilter = .all,
        sort: FilmSort = .watchedDateDesc
    ) {
        self.entries = entries
        self.filter = filter
        self.sort = sort
    }

    /// Replaces the source entries (e.g. after a re-sync). Filter and sort persist.
    public func update(entries: [DiaryEntry]) {
        self.entries = entries
    }

    /// The facet values available across the *entire* source set, with counts.
    /// Derived from the unfiltered entries so a chosen filter never causes its own
    /// controls to vanish. Delegates to `FilmQuery.availableFacets`.
    public var facets: Facets {
        FilmQuery.availableFacets(in: entries)
    }

    /// The filtered, sorted entries to display. Delegates to `FilmQuery.apply`.
    public var results: [DiaryEntry] {
        FilmQuery.apply(filter, sort: sort, to: entries)
    }

    /// The films of `results`, in result order (for poster walls).
    public var resultFilms: [Film] {
        results.map(\.film)
    }

    /// The number of matching entries.
    public var resultCount: Int { results.count }

    /// True when the active filter constrains nothing.
    public var hasActiveFilter: Bool { !filter.isEmpty }

    // MARK: - Filter mutations

    /// Sets the rating range from raw half-star bounds (each 1...10). A `nil`
    /// pair clears the constraint; an invalid pair is ignored.
    public func setRatingRange(minHalfStars: Int?, maxHalfStars: Int?) {
        guard let lo = minHalfStars, let hi = maxHalfStars else {
            filter.ratingRange = nil
            return
        }
        guard let lower = Rating(halfStars: lo), let upper = Rating(halfStars: hi), lower <= upper else {
            return
        }
        filter.ratingRange = lower...upper
    }

    /// Toggles a genre in/out of the filter's genre set.
    public func toggleGenre(_ name: String) {
        if filter.genres.contains(name) {
            filter.genres.remove(name)
        } else {
            filter.genres.insert(name)
        }
    }

    /// Toggles a decade in/out of the filter's decade set.
    public func toggleDecade(_ decade: Int) {
        if filter.decades.contains(decade) {
            filter.decades.remove(decade)
        } else {
            filter.decades.insert(decade)
        }
    }

    /// Sets the inclusive runtime range (minutes), or clears it with `nil`.
    public func setRuntimeRange(_ range: ClosedRange<Int>?) {
        filter.runtimeRange = range
    }

    /// Cycles a tri-state toggle: nil -> true -> false -> nil.
    public func cycleRewatch() { filter.isRewatch = Self.cycle(filter.isRewatch) }
    public func cycleLiked() { filter.isLiked = Self.cycle(filter.isLiked) }
    public func cycleReview() { filter.hasReview = Self.cycle(filter.hasReview) }

    private static func cycle(_ value: Bool?) -> Bool? {
        switch value {
        case .none: return true
        case .some(true): return false
        case .some(false): return nil
        }
    }

    /// Sets the free-text search query (whitespace-only is treated as no constraint).
    public func setSearch(_ text: String) {
        filter.freeText = text
    }

    /// Clears every filter dimension, leaving the sort untouched.
    public func clearFilters() {
        filter = .all
    }

    // MARK: - Active filter summary

    /// Human-readable chips describing each active filter dimension, for display
    /// above the results. Each chip carries a `clear` closure-free `Kind` so the
    /// view can offer per-dimension removal.
    public var activeFilterChips: [ActiveFilterChip] {
        var chips: [ActiveFilterChip] = []
        if let range = filter.ratingRange {
            let label = range.lowerBound == range.upperBound
                ? range.lowerBound.starString
                : "\(range.lowerBound.starString)–\(range.upperBound.starString)"
            chips.append(ActiveFilterChip(kind: .rating, label: label))
        }
        for genre in filter.genres.sorted() {
            chips.append(ActiveFilterChip(kind: .genre(genre), label: genre))
        }
        for decade in filter.decades.sorted() {
            chips.append(ActiveFilterChip(kind: .decade(decade), label: "\(decade)s"))
        }
        if let range = filter.runtimeRange {
            chips.append(ActiveFilterChip(kind: .runtime, label: "\(range.lowerBound)–\(range.upperBound) min"))
        }
        if let value = filter.isRewatch {
            chips.append(ActiveFilterChip(kind: .rewatch, label: value ? "Rewatch" : "First watch"))
        }
        if let value = filter.isLiked {
            chips.append(ActiveFilterChip(kind: .liked, label: value ? "Liked" : "Not liked"))
        }
        if let value = filter.hasReview {
            chips.append(ActiveFilterChip(kind: .review, label: value ? "Reviewed" : "No review"))
        }
        if let text = filter.freeText?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
            chips.append(ActiveFilterChip(kind: .freeText, label: "“\(text)”"))
        }
        return chips
    }

    /// Removes the dimension described by `kind` from the active filter.
    public func clear(_ kind: ActiveFilterChip.Kind) {
        switch kind {
        case .rating: filter.ratingRange = nil
        case .genre(let name): filter.genres.remove(name)
        case .decade(let decade): filter.decades.remove(decade)
        case .runtime: filter.runtimeRange = nil
        case .rewatch: filter.isRewatch = nil
        case .liked: filter.isLiked = nil
        case .review: filter.hasReview = nil
        case .freeText: filter.freeText = nil
        }
    }
}

/// A display token for one active filter dimension.
public struct ActiveFilterChip: Identifiable, Hashable, Sendable {
    public enum Kind: Hashable, Sendable {
        case rating
        case genre(String)
        case decade(Int)
        case runtime
        case rewatch
        case liked
        case review
        case freeText
    }

    public let kind: Kind
    public let label: String

    public var id: Kind { kind }

    public init(kind: Kind, label: String) {
        self.kind = kind
        self.label = label
    }
}

// MARK: - FilmSort display

public extension FilmSort {
    /// A human-readable label for the sort menu.
    var displayName: String {
        switch self {
        case .watchedDateDesc: return "Recently watched"
        case .watchedDateAsc:  return "Oldest watched"
        case .ratingDesc:      return "Highest rated"
        case .ratingAsc:       return "Lowest rated"
        case .titleAsc:        return "Title A–Z"
        case .titleDesc:       return "Title Z–A"
        case .releaseYearDesc: return "Newest releases"
        case .releaseYearAsc:  return "Oldest releases"
        case .runtimeDesc:     return "Longest"
        case .runtimeAsc:      return "Shortest"
        }
    }
}
