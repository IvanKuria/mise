import Foundation
import MiseCore

/// The distinct facet values present in a set of diary entries, with counts, to
/// drive UI filter controls. A facet "count" is the number of entries that would
/// match if that single value were selected.
public struct Facets: Hashable, Sendable {
    /// A facet value paired with the number of entries exhibiting it.
    public struct Count<Value: Hashable & Sendable>: Hashable, Sendable {
        public let value: Value
        public let count: Int

        public init(value: Value, count: Int) {
            self.value = value
            self.count = count
        }
    }

    /// Distinct genre names, sorted ascending by name.
    public let genres: [Count<String>]
    /// Distinct decades (e.g. 1980), sorted ascending.
    public let decades: [Count<Int>]
    /// The inclusive span of release years present, or `nil` if none have a year.
    public let yearRange: ClosedRange<Int>?
    /// The inclusive span of runtimes (minutes) present, or `nil` if none have a runtime.
    public let runtimeRange: ClosedRange<Int>?

    public init(
        genres: [Count<String>],
        decades: [Count<Int>],
        yearRange: ClosedRange<Int>?,
        runtimeRange: ClosedRange<Int>?
    ) {
        self.genres = genres
        self.decades = decades
        self.yearRange = yearRange
        self.runtimeRange = runtimeRange
    }

    /// The empty facet set (no entries).
    public static let empty = Facets(genres: [], decades: [], yearRange: nil, runtimeRange: nil)
}
