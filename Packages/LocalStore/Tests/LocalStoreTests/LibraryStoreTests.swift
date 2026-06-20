import Foundation
import Testing
import MiseCore
@testable import LocalStore

/// Exercises the thin SwiftData adapter against an in-memory ModelContainer.
///
/// KNOWN RISK: SwiftData may fail to host inside a plain SwiftPM `swift test`
/// process. If `LibraryStore(inMemory:)` throws here, the failure is reported and
/// the pure merge/sync logic above remains fully validated without SwiftData.
@Suite("LibraryStore (SwiftData)")
struct LibraryStoreTests {

    private func fullHistory() -> WatchHistory {
        WatchHistory(
            member: Fixtures.member("alice"),
            diary: [
                Fixtures.diary("a", watched: Fixtures.date(2), rating: 8, review: "great", liked: true),
                Fixtures.diary("b", watched: Fixtures.date(1)),
            ],
            watchlist: [Fixtures.watchlist("w1", added: Fixtures.date(3))],
            lists: [Fixtures.list("l1", name: "Faves", films: ["a", "b"])],
            statistics: Fixtures.stats(watched: 2, histogram: [8: 1, 10: 3])
        )
    }

    @Test("save then load round-trips the full history")
    func roundTrip() async throws {
        let store = try LibraryStore(inMemory: true)
        let history = HistoryMerge.mergeHistory(existing: nil, fetched: fullHistory())
        try await store.save(history)

        let loaded = try #require(try await store.loadHistory(username: "alice"))
        #expect(loaded == history)
        #expect(loaded.statistics?.ratingsHistogram == [8: 1, 10: 3])
    }

    @Test("loadHistory returns nil for an unknown member")
    func missing() async throws {
        let store = try LibraryStore(inMemory: true)
        #expect(try await store.loadHistory(username: "ghost") == nil)
    }

    @Test("re-saving the same member upserts (no duplicate members or children)")
    func upsert() async throws {
        let store = try LibraryStore(inMemory: true)
        let h1 = HistoryMerge.mergeHistory(existing: nil, fetched: fullHistory())
        try await store.save(h1)
        try await store.save(h1)
        let loaded = try #require(try await store.loadHistory(username: "alice"))
        #expect(loaded.diary.count == 2)
        #expect(loaded.watchlist.count == 1)
        #expect(loaded.lists.count == 1)
    }

    @Test("SyncEngine works end-to-end with LibraryStore")
    func syncWithLibraryStore() async throws {
        let store = try LibraryStore(inMemory: true)
        let fetcher = MockFetcher(
            member: Fixtures.member("alice"),
            statistics: Fixtures.stats(watched: 1),
            logEntries: [Fixtures.diary("a")]
        )
        let engine = SyncEngine(fetcher: fetcher, store: store)
        let first = try await engine.sync(username: "alice")

        fetcher.logEntriesByID[Fixtures.member("alice").id] = [Fixtures.diary("c", watched: Fixtures.date(9))]
        let second = try await engine.sync(username: "alice")

        #expect(first.diary.map(\.id) == ["a"])
        #expect(Set(second.diary.map(\.id)) == ["a", "c"])

        let loaded = try #require(try await store.loadHistory(username: "alice"))
        #expect(loaded == second)
    }
}
