import Foundation
import MiseCore
import WatchlistPlanner

/// The observable state behind ``WatchlistView``: the "Tonight's Pick" solver
/// driven by an editable ``TonightCriteria`` and a chosen ``Ranking``.
///
/// The model is deliberately thin over the pure ``WatchlistPlanner`` so its
/// behavior is easy to test: criteria in, candidates and a pick out. Rerolling
/// advances a seed so a `.random` ranking surfaces a different film each tap.
@MainActor
@Observable
public final class WatchlistModel {

    // MARK: Inputs (immutable for the model's lifetime)

    private let watchlist: [WatchlistItem]
    private let availability: StreamingAvailability

    // MARK: Editable criteria (each dimension is independent)

    /// Maximum runtime cap in minutes, or `nil` for "any length".
    public var maxRuntimeMinutes: Int? {
        didSet { refresh() }
    }
    /// Match-any set of streaming service names; empty means "any service".
    public var selectedServices: Set<String> {
        didSet { refresh() }
    }
    /// Match-any set of genre names; empty means "any genre".
    public var selectedGenres: Set<String> {
        didSet { refresh() }
    }
    /// Minimum Letterboxd community average (stars), or `nil` for "any rating".
    public var minAverage: Double? {
        didSet { refresh() }
    }
    /// How a non-random pick is chosen, and how the grid is ordered.
    public var ranking: Ranking {
        didSet { refresh() }
    }

    // MARK: Derived, observable outputs

    /// The films matching every active criterion, ordered for display.
    public private(set) var candidates: [WatchlistItem] = []
    /// Tonight's chosen film, or `nil` when nothing matches.
    public private(set) var pick: WatchlistItem? = nil

    /// The seed that drives reroll. Bumped on every ``reroll()``.
    private var seed: UInt64

    public init(
        watchlist: [WatchlistItem],
        availability: StreamingAvailability = .init(),
        ranking: Ranking = .random(seed: 0),
        seed: UInt64 = 0x5EED
    ) {
        self.watchlist = watchlist
        self.availability = availability
        self.maxRuntimeMinutes = nil
        self.selectedServices = []
        self.selectedGenres = []
        self.minAverage = nil
        self.ranking = ranking
        self.seed = seed
        refresh()
    }

    // MARK: Facets (the vocabulary the UI offers)

    /// Every genre appearing in the watchlist, sorted alphabetically.
    public var availableGenres: [String] {
        let names = watchlist.flatMap { $0.film.genres.map(\.name) }
        return Set(names).sorted()
    }

    /// Every streaming service that at least one watchlist film is available on,
    /// sorted alphabetically.
    public var availableServices: [String] {
        let services = watchlist.flatMap { availability.services(for: $0.film.id) }
        return Set(services).sorted()
    }

    /// The runtime caps offered as quick presets, restricted to those that could
    /// ever match (i.e. at least one film fits). Always includes "any" (nil) in
    /// the UI layer; this returns the concrete caps only.
    public var runtimeOptions: [Int] {
        let caps = [90, 100, 120, 150]
        let minRuntime = watchlist.compactMap { $0.film.runtimeMinutes }.min()
        guard let minRuntime else { return caps }
        return caps.filter { $0 >= minRuntime }
    }

    /// The minimum-average presets the UI offers.
    public var minAverageOptions: [Double] { [3.0, 3.5, 4.0, 4.5] }

    /// Whether any criterion is currently narrowing the watchlist.
    public var hasActiveCriteria: Bool {
        maxRuntimeMinutes != nil
            || !selectedServices.isEmpty
            || !selectedGenres.isEmpty
            || minAverage != nil
    }

    /// The availability data backing this model, for the hero's rationale line.
    public var availabilitySnapshot: StreamingAvailability { availability }

    /// The criteria as a value type, for the planner and for tests.
    public var criteria: TonightCriteria {
        TonightCriteria(
            maxRuntimeMinutes: maxRuntimeMinutes,
            requiredServices: selectedServices,
            genres: selectedGenres,
            minLetterboxdAverage: minAverage
        )
    }

    // MARK: Mutations

    /// Toggle a genre in/out of the active set.
    public func toggleGenre(_ name: String) {
        if selectedGenres.contains(name) {
            selectedGenres.remove(name)
        } else {
            selectedGenres.insert(name)
        }
    }

    /// Toggle a streaming service in/out of the active set.
    public func toggleService(_ name: String) {
        if selectedServices.contains(name) {
            selectedServices.remove(name)
        } else {
            selectedServices.insert(name)
        }
    }

    /// Clear every criterion back to "any".
    public func clearCriteria() {
        // Set fields directly; each `didSet` calls refresh, but the final state
        // is what matters and refresh is cheap.
        maxRuntimeMinutes = nil
        selectedServices = []
        selectedGenres = []
        minAverage = nil
    }

    /// Pick a different film. Advances the seed so a `.random` ranking changes,
    /// and switches a non-random ranking into `.random` so the button always
    /// feels alive (you asked for a fresh suggestion).
    public func reroll() {
        seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        ranking = .random(seed: seed)
        // `ranking`'s didSet already refreshed.
    }

    // MARK: Engine

    /// The seed-aware ranking actually handed to the planner. For `.random` we
    /// substitute the live ``seed`` so reroll varies the result even if the
    /// caller passed `.random(seed:)` with a fixed value.
    private var effectiveRanking: Ranking {
        switch ranking {
        case .random:
            return .random(seed: seed)
        case .shortestFirst, .highestRated:
            return ranking
        }
    }

    /// Recompute ``candidates`` and ``pick`` from the current criteria/ranking.
    private func refresh() {
        let pool = WatchlistPlanner.candidates(
            watchlist,
            availability: availability,
            criteria: criteria
        )

        // Order the grid to mirror the active ranking so the hero pick visually
        // "comes from" the top of the wall.
        switch effectiveRanking {
        case .random(let s):
            candidates = WatchlistPlanner.shuffle(
                watchlist,
                availability: availability,
                criteria: criteria,
                seed: s
            )
        case .shortestFirst, .highestRated:
            // Reuse the planner's pick ordering by sorting the pool the same way:
            // ask for the full ordering via repeated picks would be wasteful, so
            // sort locally using the same comparators the planner exposes through
            // `pick`. We approximate by placing the planner's pick first.
            candidates = orderedDeterministically(pool, ranking: effectiveRanking)
        }

        pick = WatchlistPlanner.pick(
            watchlist,
            availability: availability,
            criteria: criteria,
            ranking: effectiveRanking
        )
    }

    /// Deterministic ordering matching the planner's ranking semantics for the
    /// non-random rankings, so the grid and the hero agree.
    private func orderedDeterministically(
        _ pool: [WatchlistItem],
        ranking: Ranking
    ) -> [WatchlistItem] {
        switch ranking {
        case .shortestFirst:
            return pool.sorted { shortestFirst($0, $1) }
        case .highestRated:
            return pool.sorted { highestRated($0, $1) }
        case .random:
            return pool
        }
    }

    private func shortestFirst(_ a: WatchlistItem, _ b: WatchlistItem) -> Bool {
        let ra = a.film.runtimeMinutes ?? .max
        let rb = b.film.runtimeMinutes ?? .max
        if ra != rb { return ra < rb }
        let aa = a.film.letterboxdAverageRating ?? -.infinity
        let ab = b.film.letterboxdAverageRating ?? -.infinity
        if aa != ab { return aa > ab }
        return a.id < b.id
    }

    private func highestRated(_ a: WatchlistItem, _ b: WatchlistItem) -> Bool {
        let aa = a.film.letterboxdAverageRating ?? -.infinity
        let ab = b.film.letterboxdAverageRating ?? -.infinity
        if aa != ab { return aa > ab }
        let ra = a.film.runtimeMinutes ?? .max
        let rb = b.film.runtimeMinutes ?? .max
        if ra != rb { return ra < rb }
        return a.id < b.id
    }
}
