import Testing
import MiseCore
@testable import WatchlistPlanner

@Suite("Candidate filtering")
struct CandidatesTests {

    @Test("Empty criteria returns the whole watchlist")
    func emptyCriteriaPassesAll() {
        let watchlist = [Fixtures.item("a"), Fixtures.item("b")]
        let result = WatchlistPlanner.candidates(
            watchlist,
            availability: StreamingAvailability(),
            criteria: TonightCriteria()
        )
        #expect(result.map(\.id) == ["a", "b"])
    }

    @Test("maxRuntimeMinutes filters out longer films")
    func runtimeFilter() {
        let watchlist = [
            Fixtures.item("short", runtime: 90),
            Fixtures.item("long", runtime: 180),
            Fixtures.item("exact", runtime: 120),
        ]
        let result = WatchlistPlanner.candidates(
            watchlist,
            availability: StreamingAvailability(),
            criteria: TonightCriteria(maxRuntimeMinutes: 120)
        )
        #expect(Set(result.map(\.id)) == ["short", "exact"])
    }

    @Test("Films with unknown runtime are excluded when a runtime cap is set")
    func unknownRuntimeExcludedWithCap() {
        let watchlist = [Fixtures.item("unknown", runtime: nil), Fixtures.item("ok", runtime: 90)]
        let result = WatchlistPlanner.candidates(
            watchlist,
            availability: StreamingAvailability(),
            criteria: TonightCriteria(maxRuntimeMinutes: 120)
        )
        #expect(result.map(\.id) == ["ok"])
    }

    @Test("Unknown runtime is allowed when no cap is set")
    func unknownRuntimeAllowedWithoutCap() {
        let watchlist = [Fixtures.item("unknown", runtime: nil)]
        let result = WatchlistPlanner.candidates(
            watchlist,
            availability: StreamingAvailability(),
            criteria: TonightCriteria()
        )
        #expect(result.map(\.id) == ["unknown"])
    }

    @Test("requiredServices matches any service the film is available on")
    func serviceFilterMatchAny() {
        let watchlist = [Fixtures.item("a"), Fixtures.item("b"), Fixtures.item("c")]
        let availability = StreamingAvailability(byFilmID: [
            "a": ["Netflix"],
            "b": ["Hulu", "Max"],
            "c": ["Disney+"],
        ])
        let result = WatchlistPlanner.candidates(
            watchlist,
            availability: availability,
            criteria: TonightCriteria(requiredServices: ["Netflix", "Max"])
        )
        #expect(Set(result.map(\.id)) == ["a", "b"])
    }

    @Test("requiredServices excludes films with no availability data")
    func serviceFilterExcludesMissing() {
        let watchlist = [Fixtures.item("a"), Fixtures.item("missing")]
        let availability = StreamingAvailability(byFilmID: ["a": ["Netflix"]])
        let result = WatchlistPlanner.candidates(
            watchlist,
            availability: availability,
            criteria: TonightCriteria(requiredServices: ["Netflix"])
        )
        #expect(result.map(\.id) == ["a"])
    }

    @Test("Empty requiredServices ignores availability entirely")
    func emptyServicesIgnoresAvailability() {
        let watchlist = [Fixtures.item("a"), Fixtures.item("b")]
        let result = WatchlistPlanner.candidates(
            watchlist,
            availability: StreamingAvailability(),
            criteria: TonightCriteria(requiredServices: [])
        )
        #expect(result.map(\.id) == ["a", "b"])
    }

    @Test("genres filter matches any requested genre")
    func genreFilterMatchAny() {
        let watchlist = [
            Fixtures.item("a", genres: ["Horror"]),
            Fixtures.item("b", genres: ["Comedy", "Drama"]),
            Fixtures.item("c", genres: ["Sci-Fi"]),
        ]
        let result = WatchlistPlanner.candidates(
            watchlist,
            availability: StreamingAvailability(),
            criteria: TonightCriteria(genres: ["Comedy", "Horror"])
        )
        #expect(Set(result.map(\.id)) == ["a", "b"])
    }

    @Test("genre matching is case-insensitive")
    func genreFilterCaseInsensitive() {
        let watchlist = [Fixtures.item("a", genres: ["Horror"])]
        let result = WatchlistPlanner.candidates(
            watchlist,
            availability: StreamingAvailability(),
            criteria: TonightCriteria(genres: ["horror"])
        )
        #expect(result.map(\.id) == ["a"])
    }

    @Test("minLetterboxdAverage filters out lower-rated and unknown-rated films")
    func minAverageFilter() {
        let watchlist = [
            Fixtures.item("high", avg: 4.2),
            Fixtures.item("low", avg: 3.0),
            Fixtures.item("exact", avg: 3.5),
            Fixtures.item("unrated", avg: nil),
        ]
        let result = WatchlistPlanner.candidates(
            watchlist,
            availability: StreamingAvailability(),
            criteria: TonightCriteria(minLetterboxdAverage: 3.5)
        )
        #expect(Set(result.map(\.id)) == ["high", "exact"])
    }

    @Test("All criteria compose (AND across dimensions)")
    func allCriteriaCompose() {
        let watchlist = [
            Fixtures.item("win", runtime: 100, genres: ["Drama"], avg: 4.0),
            Fixtures.item("tooLong", runtime: 200, genres: ["Drama"], avg: 4.0),
            Fixtures.item("wrongGenre", runtime: 100, genres: ["Comedy"], avg: 4.0),
            Fixtures.item("tooLow", runtime: 100, genres: ["Drama"], avg: 2.0),
            Fixtures.item("noService", runtime: 100, genres: ["Drama"], avg: 4.0),
        ]
        let availability = StreamingAvailability(byFilmID: [
            "win": ["Netflix"],
            "tooLong": ["Netflix"],
            "wrongGenre": ["Netflix"],
            "tooLow": ["Netflix"],
            "noService": ["Hulu"],
        ])
        let result = WatchlistPlanner.candidates(
            watchlist,
            availability: availability,
            criteria: TonightCriteria(
                maxRuntimeMinutes: 120,
                requiredServices: ["Netflix"],
                genres: ["Drama"],
                minLetterboxdAverage: 3.5
            )
        )
        #expect(result.map(\.id) == ["win"])
    }
}
