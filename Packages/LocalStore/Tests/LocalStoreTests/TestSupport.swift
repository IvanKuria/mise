import Foundation
import MiseCore
@testable import LocalStore

// MARK: - Builders

enum Fixtures {
    static func film(_ id: String, name: String? = nil, year: Int? = nil) -> Film {
        Film(id: id, name: name ?? "Film \(id)", releaseYear: year)
    }

    static func diary(
        _ id: String,
        filmID: String? = nil,
        watched: Date? = nil,
        rating: Int? = nil,
        review: String? = nil,
        liked: Bool = false,
        rewatch: Bool = false
    ) -> DiaryEntry {
        DiaryEntry(
            id: id,
            film: film(filmID ?? id),
            watchedDate: watched,
            rating: rating.flatMap { Rating(halfStars: $0) },
            isRewatch: rewatch,
            isLiked: liked,
            review: review
        )
    }

    static func watchlist(_ filmID: String, added: Date? = nil) -> WatchlistItem {
        WatchlistItem(film: film(filmID), addedDate: added)
    }

    static func list(_ id: String, name: String, films: [String] = []) -> FilmList {
        FilmList(id: id, name: name, films: films.map { film($0) })
    }

    static func member(_ username: String = "alice", id: String = "m1") -> MemberSummary {
        MemberSummary(id: id, username: username, displayName: username.capitalized)
    }

    static func stats(watched: Int = 0, histogram: [Int: Int] = [:]) -> MemberStatistics {
        MemberStatistics(watchedFilmCount: watched, ratingsHistogram: histogram)
    }

    static func date(_ daysFromEpoch: Int) -> Date {
        Date(timeIntervalSince1970: TimeInterval(daysFromEpoch) * 86_400)
    }
}

// MARK: - Mock fetcher

/// In-memory, network-free `LetterboxdFetching`. Records call counts so tests can
/// assert idempotency of orchestration.
final class MockFetcher: LetterboxdFetching, @unchecked Sendable {
    var memberByUsername: [String: MemberSummary]
    var statisticsByID: [String: MemberStatistics]
    var logEntriesByID: [String: [DiaryEntry]]
    var watchlistByID: [String: [WatchlistItem]]
    var listsByID: [String: [FilmList]]

    private(set) var memberCalls = 0
    private(set) var logEntriesCalls = 0

    init(
        member: MemberSummary,
        statistics: MemberStatistics = Fixtures.stats(),
        logEntries: [DiaryEntry] = [],
        watchlist: [WatchlistItem] = [],
        lists: [FilmList] = []
    ) {
        self.memberByUsername = [member.username: member]
        self.statisticsByID = [member.id: statistics]
        self.logEntriesByID = [member.id: logEntries]
        self.watchlistByID = [member.id: watchlist]
        self.listsByID = [member.id: lists]
    }

    func member(username: String) async throws -> MemberSummary {
        memberCalls += 1
        guard let m = memberByUsername[username] else {
            throw MockError.notFound("member \(username)")
        }
        return m
    }

    func statistics(memberID: String) async throws -> MemberStatistics {
        statisticsByID[memberID] ?? Fixtures.stats()
    }

    func logEntries(memberID: String, perPage: Int, cursor: String?) async throws -> [DiaryEntry] {
        logEntriesCalls += 1
        return logEntriesByID[memberID] ?? []
    }

    func watchlist(memberID: String) async throws -> [WatchlistItem] {
        watchlistByID[memberID] ?? []
    }

    func lists(memberID: String) async throws -> [FilmList] {
        listsByID[memberID] ?? []
    }

    enum MockError: Error { case notFound(String) }
}

// MARK: - In-memory store

/// Pure in-memory `HistoryStoring` for SyncEngine tests that don't depend on
/// SwiftData hosting.
actor InMemoryStore: HistoryStoring {
    private var histories: [String: WatchHistory] = [:]
    private(set) var saveCount = 0

    func loadHistory(username: String) async throws -> WatchHistory? {
        histories[username]
    }

    func save(_ history: WatchHistory) async throws {
        saveCount += 1
        histories[history.member.username] = history
    }
}
