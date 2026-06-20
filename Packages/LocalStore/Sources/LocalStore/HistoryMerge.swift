import Foundation
import MiseCore

/// Pure, value-only merge logic for incremental sync.
///
/// These functions contain ALL the valuable correctness logic (upsert,
/// de-duplication, conflict resolution, deterministic ordering) and have NO
/// dependency on SwiftData or the network — they operate purely on MiseCore
/// values, so they are fully unit-testable.
///
/// Invariants for every `merge*`:
/// - **Upsert by id**: an id present in both `existing` and `fetched` is replaced
///   by the fetched value (fetched wins on conflict).
/// - **Incremental**: ids present only in `existing` are preserved (a partial
///   refresh never drops history it didn't re-fetch).
/// - **De-duplicated**: the result has at most one element per id.
/// - **Deterministic order**: the result order depends only on the merged set,
///   not on input order.
public enum HistoryMerge {

    // MARK: - Diary

    /// Merge fetched diary entries into existing ones.
    ///
    /// Order: `watchedDate` descending (nil dates last), tie-broken by `id`
    /// ascending so the result is fully deterministic.
    public static func mergeDiary(existing: [DiaryEntry], fetched: [DiaryEntry]) -> [DiaryEntry] {
        var byID: [String: DiaryEntry] = [:]
        byID.reserveCapacity(existing.count + fetched.count)
        for entry in existing { byID[entry.id] = entry }
        for entry in fetched { byID[entry.id] = entry } // fetched wins
        return byID.values.sorted(by: diaryOrder)
    }

    /// The ids in `fetched` that are genuinely new (not already in `existing`).
    /// Returned sorted for determinism.
    public static func incrementalNewEntries(existing: [DiaryEntry], fetched: [DiaryEntry]) -> [String] {
        let existingIDs = Set(existing.map(\.id))
        var seen = Set<String>()
        var result: [String] = []
        for entry in fetched where !existingIDs.contains(entry.id) && seen.insert(entry.id).inserted {
            result.append(entry.id)
        }
        return result.sorted()
    }

    private static func diaryOrder(_ a: DiaryEntry, _ b: DiaryEntry) -> Bool {
        switch (a.watchedDate, b.watchedDate) {
        case let (x?, y?):
            if x != y { return x > y }
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        case (nil, nil):
            break
        }
        return a.id < b.id
    }

    // MARK: - Watchlist

    /// Merge fetched watchlist items into existing ones (id == `film.id`).
    ///
    /// Order: `addedDate` descending (nil dates last), tie-broken by id ascending.
    public static func mergeWatchlist(existing: [WatchlistItem], fetched: [WatchlistItem]) -> [WatchlistItem] {
        var byID: [String: WatchlistItem] = [:]
        byID.reserveCapacity(existing.count + fetched.count)
        for item in existing { byID[item.id] = item }
        for item in fetched { byID[item.id] = item } // fetched wins
        return byID.values.sorted(by: watchlistOrder)
    }

    private static func watchlistOrder(_ a: WatchlistItem, _ b: WatchlistItem) -> Bool {
        switch (a.addedDate, b.addedDate) {
        case let (x?, y?):
            if x != y { return x > y }
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        case (nil, nil):
            break
        }
        return a.id < b.id
    }

    // MARK: - Lists

    /// Merge fetched lists into existing ones, upserting by `FilmList.id`.
    ///
    /// Order: by `name` (case-insensitive) ascending, tie-broken by id ascending.
    public static func mergeLists(existing: [FilmList], fetched: [FilmList]) -> [FilmList] {
        var byID: [String: FilmList] = [:]
        byID.reserveCapacity(existing.count + fetched.count)
        for list in existing { byID[list.id] = list }
        for list in fetched { byID[list.id] = list } // fetched wins
        return byID.values.sorted(by: listOrder)
    }

    private static func listOrder(_ a: FilmList, _ b: FilmList) -> Bool {
        let an = a.name.lowercased(), bn = b.name.lowercased()
        if an != bn { return an < bn }
        return a.id < b.id
    }

    // MARK: - WatchHistory

    /// Merge a freshly-fetched `WatchHistory` into a stored one, applying the
    /// per-collection merges above. Member identity and (when present) statistics
    /// are taken from the fetched history. If `fetched.statistics` is nil the
    /// existing statistics are preserved.
    public static func mergeHistory(existing: WatchHistory?, fetched: WatchHistory) -> WatchHistory {
        guard let existing else { return normalized(fetched) }
        return WatchHistory(
            member: fetched.member,
            diary: mergeDiary(existing: existing.diary, fetched: fetched.diary),
            watchlist: mergeWatchlist(existing: existing.watchlist, fetched: fetched.watchlist),
            lists: mergeLists(existing: existing.lists, fetched: fetched.lists),
            statistics: fetched.statistics ?? existing.statistics
        )
    }

    /// A first-sync history put into the same deterministic order the merges use,
    /// so a freshly-stored history and a re-merged one compare equal.
    private static func normalized(_ history: WatchHistory) -> WatchHistory {
        WatchHistory(
            member: history.member,
            diary: mergeDiary(existing: [], fetched: history.diary),
            watchlist: mergeWatchlist(existing: [], fetched: history.watchlist),
            lists: mergeLists(existing: [], fetched: history.lists),
            statistics: history.statistics
        )
    }
}
