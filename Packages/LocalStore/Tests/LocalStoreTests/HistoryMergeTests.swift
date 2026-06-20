import Foundation
import Testing
import MiseCore
@testable import LocalStore

@Suite("Diary merge")
struct DiaryMergeTests {

    @Test("first sync: empty existing keeps all fetched, deduped")
    func firstSync() {
        let fetched = [Fixtures.diary("b"), Fixtures.diary("a"), Fixtures.diary("a")]
        let merged = HistoryMerge.mergeDiary(existing: [], fetched: fetched)
        #expect(merged.map(\.id) == ["a", "b"]) // nil dates -> id ascending
        #expect(Set(merged.map(\.id)).count == merged.count)
    }

    @Test("upsert idempotency: re-merging the same fetch produces no duplicates")
    func idempotent() {
        let fetched = [Fixtures.diary("a"), Fixtures.diary("b")]
        let once = HistoryMerge.mergeDiary(existing: [], fetched: fetched)
        let twice = HistoryMerge.mergeDiary(existing: once, fetched: fetched)
        #expect(once == twice)
        #expect(twice.count == 2)
    }

    @Test("incremental refresh: new entries added, old preserved")
    func incremental() {
        let existing = [Fixtures.diary("a"), Fixtures.diary("b")]
        let fetched = [Fixtures.diary("c")] // a partial refresh that didn't re-fetch a/b
        let merged = HistoryMerge.mergeDiary(existing: existing, fetched: fetched)
        #expect(Set(merged.map(\.id)) == ["a", "b", "c"])
    }

    @Test("conflict resolution: fetched wins")
    func fetchedWins() {
        let existing = [Fixtures.diary("a", rating: 4, review: "old")]
        let fetched = [Fixtures.diary("a", rating: 10, review: "new")]
        let merged = HistoryMerge.mergeDiary(existing: existing, fetched: fetched)
        #expect(merged.count == 1)
        #expect(merged[0].rating?.halfStars == 10)
        #expect(merged[0].review == "new")
    }

    @Test("ordering: watchedDate desc, nil last, id tiebreak")
    func ordering() {
        let entries = [
            Fixtures.diary("z", watched: Fixtures.date(1)),
            Fixtures.diary("y", watched: Fixtures.date(5)),
            Fixtures.diary("x", watched: nil),
            Fixtures.diary("w", watched: nil),
            Fixtures.diary("v", watched: Fixtures.date(5)), // tie with y -> id tiebreak
        ]
        let merged = HistoryMerge.mergeDiary(existing: [], fetched: entries)
        #expect(merged.map(\.id) == ["v", "y", "z", "w", "x"])
    }

    @Test("deterministic regardless of input order")
    func deterministic() {
        let a = [Fixtures.diary("a", watched: Fixtures.date(2)), Fixtures.diary("b", watched: Fixtures.date(1))]
        let b = a.reversed().map { $0 }
        #expect(HistoryMerge.mergeDiary(existing: [], fetched: a)
                == HistoryMerge.mergeDiary(existing: [], fetched: b))
    }

    @Test("incrementalNewEntries returns only genuinely new ids, sorted")
    func newEntries() {
        let existing = [Fixtures.diary("a"), Fixtures.diary("b")]
        let fetched = [Fixtures.diary("c"), Fixtures.diary("a"), Fixtures.diary("d"), Fixtures.diary("d")]
        #expect(HistoryMerge.incrementalNewEntries(existing: existing, fetched: fetched) == ["c", "d"])
    }

    @Test("incrementalNewEntries empty when nothing new")
    func noNewEntries() {
        let existing = [Fixtures.diary("a")]
        #expect(HistoryMerge.incrementalNewEntries(existing: existing, fetched: [Fixtures.diary("a")]).isEmpty)
    }
}

@Suite("Watchlist merge")
struct WatchlistMergeTests {

    @Test("upsert by film id, fetched wins, deduped")
    func upsert() {
        let existing = [Fixtures.watchlist("f1", added: Fixtures.date(1))]
        let fetched = [Fixtures.watchlist("f1", added: Fixtures.date(9)), Fixtures.watchlist("f2")]
        let merged = HistoryMerge.mergeWatchlist(existing: existing, fetched: fetched)
        #expect(merged.count == 2)
        let f1 = merged.first { $0.id == "f1" }
        #expect(f1?.addedDate == Fixtures.date(9))
    }

    @Test("idempotent")
    func idempotent() {
        let fetched = [Fixtures.watchlist("f1"), Fixtures.watchlist("f2")]
        let once = HistoryMerge.mergeWatchlist(existing: [], fetched: fetched)
        #expect(once == HistoryMerge.mergeWatchlist(existing: once, fetched: fetched))
    }

    @Test("ordering: addedDate desc, nil last, id tiebreak")
    func ordering() {
        let items = [
            Fixtures.watchlist("c", added: nil),
            Fixtures.watchlist("a", added: Fixtures.date(3)),
            Fixtures.watchlist("b", added: Fixtures.date(7)),
        ]
        let merged = HistoryMerge.mergeWatchlist(existing: [], fetched: items)
        #expect(merged.map(\.id) == ["b", "a", "c"])
    }

    @Test("incremental: old preserved")
    func incremental() {
        let existing = [Fixtures.watchlist("a"), Fixtures.watchlist("b")]
        let merged = HistoryMerge.mergeWatchlist(existing: existing, fetched: [Fixtures.watchlist("c")])
        #expect(Set(merged.map(\.id)) == ["a", "b", "c"])
    }
}

@Suite("Lists merge")
struct ListsMergeTests {

    @Test("upsert by id, fetched wins")
    func upsert() {
        let existing = [Fixtures.list("l1", name: "Old", films: ["a"])]
        let fetched = [Fixtures.list("l1", name: "New", films: ["a", "b"])]
        let merged = HistoryMerge.mergeLists(existing: existing, fetched: fetched)
        #expect(merged.count == 1)
        #expect(merged[0].name == "New")
        #expect(merged[0].films.count == 2)
    }

    @Test("ordering: case-insensitive name asc, id tiebreak")
    func ordering() {
        let lists = [
            Fixtures.list("l3", name: "banana"),
            Fixtures.list("l1", name: "Apple"),
            Fixtures.list("l2", name: "apple"), // tie with l1 -> id tiebreak
        ]
        let merged = HistoryMerge.mergeLists(existing: [], fetched: lists)
        #expect(merged.map(\.id) == ["l1", "l2", "l3"])
    }

    @Test("incremental + idempotent")
    func incrementalIdempotent() {
        let existing = [Fixtures.list("l1", name: "A")]
        let fetched = [Fixtures.list("l2", name: "B")]
        let merged = HistoryMerge.mergeLists(existing: existing, fetched: fetched)
        #expect(Set(merged.map(\.id)) == ["l1", "l2"])
        #expect(merged == HistoryMerge.mergeLists(existing: merged, fetched: fetched))
    }
}

@Suite("History merge")
struct HistoryMergeTests {

    @Test("first sync (nil existing) normalizes ordering")
    func firstSync() {
        let fetched = WatchHistory(
            member: Fixtures.member(),
            diary: [Fixtures.diary("b"), Fixtures.diary("a")],
            statistics: Fixtures.stats(watched: 2)
        )
        let merged = HistoryMerge.mergeHistory(existing: nil, fetched: fetched)
        #expect(merged.diary.map(\.id) == ["a", "b"])
        #expect(merged.statistics?.watchedFilmCount == 2)
    }

    @Test("incremental merge preserves old, adds new across all collections")
    func incremental() {
        let existing = WatchHistory(
            member: Fixtures.member(),
            diary: [Fixtures.diary("a")],
            watchlist: [Fixtures.watchlist("w1")],
            lists: [Fixtures.list("l1", name: "Keep")],
            statistics: Fixtures.stats(watched: 1)
        )
        let fetched = WatchHistory(
            member: Fixtures.member(),
            diary: [Fixtures.diary("b")],
            watchlist: [Fixtures.watchlist("w2")],
            lists: [Fixtures.list("l2", name: "Add")],
            statistics: nil
        )
        let merged = HistoryMerge.mergeHistory(existing: existing, fetched: fetched)
        #expect(Set(merged.diary.map(\.id)) == ["a", "b"])
        #expect(Set(merged.watchlist.map(\.id)) == ["w1", "w2"])
        #expect(Set(merged.lists.map(\.id)) == ["l1", "l2"])
        // nil fetched statistics -> existing preserved
        #expect(merged.statistics?.watchedFilmCount == 1)
    }

    @Test("re-merge idempotency at the history level")
    func idempotent() {
        let fetched = WatchHistory(
            member: Fixtures.member(),
            diary: [Fixtures.diary("a"), Fixtures.diary("b")],
            watchlist: [Fixtures.watchlist("w1")],
            lists: [Fixtures.list("l1", name: "X")],
            statistics: Fixtures.stats(watched: 2)
        )
        let once = HistoryMerge.mergeHistory(existing: nil, fetched: fetched)
        let twice = HistoryMerge.mergeHistory(existing: once, fetched: fetched)
        #expect(once == twice)
    }
}
