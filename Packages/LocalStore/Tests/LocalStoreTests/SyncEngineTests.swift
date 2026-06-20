import Foundation
import Testing
import MiseCore
@testable import LocalStore

@Suite("SyncEngine")
struct SyncEngineTests {

    @Test("first sync stores fetched history and returns it normalized")
    func firstSync() async throws {
        let fetcher = MockFetcher(
            member: Fixtures.member("alice"),
            statistics: Fixtures.stats(watched: 3),
            logEntries: [Fixtures.diary("b"), Fixtures.diary("a")],
            watchlist: [Fixtures.watchlist("w1")],
            lists: [Fixtures.list("l1", name: "Faves")]
        )
        let store = InMemoryStore()
        let engine = SyncEngine(fetcher: fetcher, store: store)

        let result = try await engine.sync(username: "alice")
        #expect(result.diary.map(\.id) == ["a", "b"])
        #expect(result.statistics?.watchedFilmCount == 3)

        let stored = try await store.loadHistory(username: "alice")
        #expect(stored == result)
    }

    @Test("re-sync is idempotent: no duplicates")
    func resyncIdempotent() async throws {
        let fetcher = MockFetcher(
            member: Fixtures.member("alice"),
            logEntries: [Fixtures.diary("a"), Fixtures.diary("b")]
        )
        let store = InMemoryStore()
        let engine = SyncEngine(fetcher: fetcher, store: store)

        let first = try await engine.sync(username: "alice")
        let second = try await engine.sync(username: "alice")
        #expect(first == second)
        #expect(second.diary.count == 2)
    }

    @Test("incremental sync adds only new entries, preserves old")
    func incremental() async throws {
        let fetcher = MockFetcher(
            member: Fixtures.member("alice"),
            logEntries: [Fixtures.diary("a")]
        )
        let store = InMemoryStore()
        let engine = SyncEngine(fetcher: fetcher, store: store)

        _ = try await engine.sync(username: "alice")

        // Server now returns a newer entry "c" (the recent page), not the old "a".
        fetcher.logEntriesByID[Fixtures.member("alice").id] = [Fixtures.diary("c", watched: Fixtures.date(10))]
        let merged = try await engine.sync(username: "alice")

        #expect(Set(merged.diary.map(\.id)) == ["a", "c"])
    }

    @Test("conflict on re-sync: fetched entry wins")
    func conflict() async throws {
        let fetcher = MockFetcher(
            member: Fixtures.member("alice"),
            logEntries: [Fixtures.diary("a", rating: 4)]
        )
        let store = InMemoryStore()
        let engine = SyncEngine(fetcher: fetcher, store: store)
        _ = try await engine.sync(username: "alice")

        fetcher.logEntriesByID[Fixtures.member("alice").id] = [Fixtures.diary("a", rating: 10, review: "updated")]
        let merged = try await engine.sync(username: "alice")
        #expect(merged.diary.count == 1)
        #expect(merged.diary[0].rating?.halfStars == 10)
        #expect(merged.diary[0].review == "updated")
    }

    @Test("progress callback reports stages in order, ending finished")
    func progress() async throws {
        let fetcher = MockFetcher(member: Fixtures.member("alice"))
        let engine = SyncEngine(fetcher: fetcher, store: InMemoryStore())

        let box = ProgressBox()
        _ = try await engine.sync(username: "alice", onProgress: { box.append($0) })
        let stages = box.stages
        #expect(stages.first == .resolvingMember)
        #expect(stages.last == .finished)
        #expect(stages.contains(.merging))
        #expect(stages.contains(.saving))
    }

    @Test("unknown member throws")
    func unknownMember() async throws {
        let fetcher = MockFetcher(member: Fixtures.member("alice"))
        let engine = SyncEngine(fetcher: fetcher, store: InMemoryStore())
        await #expect(throws: MockFetcher.MockError.self) {
            _ = try await engine.sync(username: "nobody")
        }
    }
}

/// Thread-safe collector for progress stages.
final class ProgressBox: @unchecked Sendable {
    private let lock = NSLock()
    private var _stages: [SyncProgress] = []
    func append(_ s: SyncProgress) { lock.lock(); _stages.append(s); lock.unlock() }
    var stages: [SyncProgress] { lock.lock(); defer { lock.unlock() }; return _stages }
}
