import FilmEnrichment
import Foundation
import LocalStore
import MiseCore
import TMDBKit

// MARK: - Mock LetterboxdFetching

/// An in-memory `LetterboxdFetching` returning canned data, with no network.
/// Optionally throws from `member` to exercise the error path.
struct MockFetcher: LetterboxdFetching {
    var member: MemberSummary
    var statistics: MemberStatistics
    var diary: [DiaryEntry]
    var watchlistItems: [WatchlistItem]
    var filmLists: [FilmList]
    var errorToThrow: (any Error)?

    init(
        member: MemberSummary = MemberSummary(id: "m1", username: "tester", displayName: "Tester"),
        statistics: MemberStatistics = MemberStatistics(),
        diary: [DiaryEntry] = [],
        watchlistItems: [WatchlistItem] = [],
        filmLists: [FilmList] = [],
        errorToThrow: (any Error)? = nil
    ) {
        self.member = member
        self.statistics = statistics
        self.diary = diary
        self.watchlistItems = watchlistItems
        self.filmLists = filmLists
        self.errorToThrow = errorToThrow
    }

    func member(username: String) async throws -> MemberSummary {
        if let errorToThrow { throw errorToThrow }
        return member
    }

    func statistics(memberID: String) async throws -> MemberStatistics {
        if let errorToThrow { throw errorToThrow }
        return statistics
    }

    func logEntries(memberID: String, perPage: Int, cursor: String?) async throws -> [DiaryEntry] {
        if let errorToThrow { throw errorToThrow }
        return diary
    }

    func watchlist(memberID: String) async throws -> [WatchlistItem] {
        if let errorToThrow { throw errorToThrow }
        return watchlistItems
    }

    func lists(memberID: String) async throws -> [FilmList] {
        if let errorToThrow { throw errorToThrow }
        return filmLists
    }
}

// MARK: - In-memory HistoryStoring

/// A trivial in-memory store, keyed by username.
actor InMemoryStore: HistoryStoring {
    private var storage: [String: WatchHistory] = [:]

    func loadHistory(username: String) async throws -> WatchHistory? {
        storage[username]
    }

    func save(_ history: WatchHistory) async throws {
        storage[history.member.username] = history
    }

    func saved(for username: String) -> WatchHistory? {
        storage[username]
    }
}

// MARK: - Mock MovieMetadataProviding

/// A mock TMDB provider. `search` returns a single result whose id is derived
/// from the title; `movie` returns canned metadata so enrichment is observable.
struct MockMetadataProvider: MovieMetadataProviding {
    var movieToReturn: TMDBMovie
    var searchResult: TMDBSearchResult

    init(
        tmdbID: Int = 42,
        runtime: Int? = 132,
        genres: [String] = ["Drama", "Thriller"],
        posterPath: String? = "/poster.jpg"
    ) {
        self.movieToReturn = TMDBMovie(
            id: tmdbID,
            title: "Matched Movie",
            posterPath: posterPath,
            runtime: runtime,
            releaseDate: "2019-05-30",
            genres: genres
        )
        self.searchResult = TMDBSearchResult(
            id: tmdbID,
            title: "Matched Movie",
            releaseYear: 2019,
            posterPath: posterPath
        )
    }

    func search(title: String, year: Int?) async throws -> [TMDBSearchResult] {
        [searchResult]
    }

    func movie(tmdbID: Int) async throws -> TMDBMovie {
        movieToReturn
    }
}

// MARK: - Fixtures

enum Fixtures {
    /// A bare film with no TMDB metadata, ripe for enrichment.
    static func bareFilm(id: String = "f1", name: String = "Parasite", year: Int? = 2019) -> Film {
        Film(id: id, name: name, releaseYear: year)
    }

    static func diaryEntry(id: String = "d1", film: Film) -> DiaryEntry {
        DiaryEntry(id: id, film: film, rating: nil)
    }
}

struct TestError: Error, LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

/// A thread-safe one-shot flag for asserting whether a `@Sendable` closure ran.
final class CallFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var called = false

    func set() {
        lock.lock(); defer { lock.unlock() }
        called = true
    }

    var wasCalled: Bool {
        lock.lock(); defer { lock.unlock() }
        return called
    }
}
