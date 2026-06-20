import Testing
import MiseCore
@testable import WatchlistPlanner

@Suite("Pick & shuffle")
struct PickTests {

    // MARK: shortestFirst

    @Test("shortestFirst picks the minimum runtime")
    func shortestFirstPicksShortest() {
        let watchlist = [
            Fixtures.item("a", runtime: 120),
            Fixtures.item("b", runtime: 90),
            Fixtures.item("c", runtime: 150),
        ]
        let pick = WatchlistPlanner.pick(
            watchlist,
            availability: StreamingAvailability(),
            criteria: TonightCriteria(),
            ranking: .shortestFirst
        )
        #expect(pick?.id == "b")
    }

    @Test("shortestFirst tie broken by higher average, then id")
    func shortestFirstTieBreak() {
        let watchlist = [
            Fixtures.item("z", runtime: 90, avg: 3.0),
            Fixtures.item("a", runtime: 90, avg: 4.5),
            Fixtures.item("m", runtime: 90, avg: 4.5),
        ]
        let pick = WatchlistPlanner.pick(
            watchlist,
            availability: StreamingAvailability(),
            criteria: TonightCriteria(),
            ranking: .shortestFirst
        )
        // Two share the highest avg (4.5); tie broken by id -> "a"
        #expect(pick?.id == "a")
    }

    // MARK: highestRated

    @Test("highestRated picks the maximum average")
    func highestRatedPicksBest() {
        let watchlist = [
            Fixtures.item("a", avg: 3.5),
            Fixtures.item("b", avg: 4.8),
            Fixtures.item("c", avg: 4.0),
        ]
        let pick = WatchlistPlanner.pick(
            watchlist,
            availability: StreamingAvailability(),
            criteria: TonightCriteria(),
            ranking: .highestRated
        )
        #expect(pick?.id == "b")
    }

    @Test("highestRated tie broken by shorter runtime, then id")
    func highestRatedTieBreak() {
        let watchlist = [
            Fixtures.item("z", runtime: 100, avg: 4.5),
            Fixtures.item("a", runtime: 130, avg: 4.5),
            Fixtures.item("m", runtime: 100, avg: 4.5),
        ]
        let pick = WatchlistPlanner.pick(
            watchlist,
            availability: StreamingAvailability(),
            criteria: TonightCriteria(),
            ranking: .highestRated
        )
        // "z" and "m" share shortest runtime (100); tie broken by id -> "m"
        #expect(pick?.id == "m")
    }

    @Test("highestRated treats unknown average as lowest")
    func highestRatedUnknownIsLowest() {
        let watchlist = [
            Fixtures.item("rated", avg: 2.0),
            Fixtures.item("unrated", avg: nil),
        ]
        let pick = WatchlistPlanner.pick(
            watchlist,
            availability: StreamingAvailability(),
            criteria: TonightCriteria(),
            ranking: .highestRated
        )
        #expect(pick?.id == "rated")
    }

    // MARK: empty

    @Test("pick returns nil when no candidates remain")
    func pickEmptyReturnsNil() {
        let watchlist = [Fixtures.item("a", runtime: 200)]
        let pick = WatchlistPlanner.pick(
            watchlist,
            availability: StreamingAvailability(),
            criteria: TonightCriteria(maxRuntimeMinutes: 90),
            ranking: .shortestFirst
        )
        #expect(pick == nil)
    }

    @Test("pick returns nil for an empty watchlist regardless of ranking")
    func pickEmptyWatchlist() {
        #expect(WatchlistPlanner.pick([], availability: StreamingAvailability(), criteria: TonightCriteria(), ranking: .highestRated) == nil)
        #expect(WatchlistPlanner.pick([], availability: StreamingAvailability(), criteria: TonightCriteria(), ranking: .random(seed: 1)) == nil)
    }

    // MARK: random(seed:)

    @Test("random pick is deterministic for the same seed")
    func randomDeterministic() {
        let watchlist = (0..<10).map { Fixtures.item("f\($0)") }
        let a = WatchlistPlanner.pick(watchlist, availability: StreamingAvailability(), criteria: TonightCriteria(), ranking: .random(seed: 42))
        let b = WatchlistPlanner.pick(watchlist, availability: StreamingAvailability(), criteria: TonightCriteria(), ranking: .random(seed: 42))
        #expect(a?.id == b?.id)
        #expect(a != nil)
    }

    @Test("random pick varies across seeds")
    func randomVariesAcrossSeeds() {
        let watchlist = (0..<20).map { Fixtures.item("f\($0)") }
        let picks = Set((0..<8).map { seed in
            WatchlistPlanner.pick(watchlist, availability: StreamingAvailability(), criteria: TonightCriteria(), ranking: .random(seed: UInt64(seed)))?.id
        })
        // At least two distinct outcomes across the seed range.
        #expect(picks.count >= 2)
    }

    @Test("random pick always returns a member of the candidate set")
    func randomPickIsCandidate() {
        let watchlist = [
            Fixtures.item("a", runtime: 80),
            Fixtures.item("b", runtime: 300),
            Fixtures.item("c", runtime: 95),
        ]
        let pick = WatchlistPlanner.pick(
            watchlist,
            availability: StreamingAvailability(),
            criteria: TonightCriteria(maxRuntimeMinutes: 120),
            ranking: .random(seed: 7)
        )
        #expect(["a", "c"].contains(pick?.id))
    }

    // MARK: shuffle

    @Test("shuffle is deterministic for the same seed")
    func shuffleDeterministic() {
        let watchlist = (0..<12).map { Fixtures.item("f\($0)") }
        let a = WatchlistPlanner.shuffle(watchlist, availability: StreamingAvailability(), criteria: TonightCriteria(), seed: 99)
        let b = WatchlistPlanner.shuffle(watchlist, availability: StreamingAvailability(), criteria: TonightCriteria(), seed: 99)
        #expect(a.map(\.id) == b.map(\.id))
    }

    @Test("shuffle is a permutation of the candidates")
    func shuffleIsPermutation() {
        let watchlist = (0..<12).map { Fixtures.item("f\($0)") }
        let shuffled = WatchlistPlanner.shuffle(watchlist, availability: StreamingAvailability(), criteria: TonightCriteria(), seed: 5)
        #expect(Set(shuffled.map(\.id)) == Set(watchlist.map(\.id)))
        #expect(shuffled.count == watchlist.count)
    }

    @Test("shuffle differs across seeds")
    func shuffleVariesAcrossSeeds() {
        let watchlist = (0..<12).map { Fixtures.item("f\($0)") }
        let a = WatchlistPlanner.shuffle(watchlist, availability: StreamingAvailability(), criteria: TonightCriteria(), seed: 1)
        let b = WatchlistPlanner.shuffle(watchlist, availability: StreamingAvailability(), criteria: TonightCriteria(), seed: 2)
        #expect(a.map(\.id) != b.map(\.id))
    }

    @Test("shuffle respects criteria filtering")
    func shuffleRespectsCriteria() {
        let watchlist = [
            Fixtures.item("a", runtime: 80),
            Fixtures.item("b", runtime: 300),
            Fixtures.item("c", runtime: 95),
        ]
        let shuffled = WatchlistPlanner.shuffle(
            watchlist,
            availability: StreamingAvailability(),
            criteria: TonightCriteria(maxRuntimeMinutes: 120),
            seed: 3
        )
        #expect(Set(shuffled.map(\.id)) == ["a", "c"])
    }

    @Test("first element of shuffle equals the random pick for the same seed")
    func shuffleHeadMatchesRandomPick() {
        let watchlist = (0..<15).map { Fixtures.item("f\($0)") }
        let head = WatchlistPlanner.shuffle(watchlist, availability: StreamingAvailability(), criteria: TonightCriteria(), seed: 314).first
        let pick = WatchlistPlanner.pick(watchlist, availability: StreamingAvailability(), criteria: TonightCriteria(), ranking: .random(seed: 314))
        #expect(head?.id == pick?.id)
    }
}
