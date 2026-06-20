import Foundation
import MiseCore

/// A coarse progress signal emitted while a sync runs.
public enum SyncProgress: Hashable, Sendable {
    case resolvingMember
    case fetchingStatistics
    case fetchingDiary
    case fetchingWatchlist
    case fetchingLists
    case merging
    case saving
    case finished
}

/// Pulls fresh public history from a `LetterboxdFetching`, merges it incrementally
/// against whatever is already stored, persists the result, and returns it.
///
/// All correctness lives in `HistoryMerge`; this actor only orchestrates I/O and
/// progress reporting.
public actor SyncEngine {
    private let fetcher: LetterboxdFetching
    private let store: HistoryStoring
    private let diaryPerPage: Int

    public init(fetcher: LetterboxdFetching, store: HistoryStoring, diaryPerPage: Int = 50) {
        self.fetcher = fetcher
        self.store = store
        self.diaryPerPage = diaryPerPage
    }

    /// Fetch fresh data for `username`, merge it into stored history, persist, and
    /// return the merged result.
    ///
    /// - Parameter onProgress: optional Sendable callback invoked as the sync
    ///   advances through its stages.
    @discardableResult
    public func sync(
        username: String,
        onProgress: (@Sendable (SyncProgress) -> Void)? = nil
    ) async throws -> WatchHistory {
        onProgress?(.resolvingMember)
        let member = try await fetcher.member(username: username)

        onProgress?(.fetchingStatistics)
        let statistics = try await fetcher.statistics(memberID: member.id)

        onProgress?(.fetchingDiary)
        let diary = try await fetcher.logEntries(memberID: member.id, perPage: diaryPerPage, cursor: nil)

        onProgress?(.fetchingWatchlist)
        let watchlist = try await fetcher.watchlist(memberID: member.id)

        onProgress?(.fetchingLists)
        let lists = try await fetcher.lists(memberID: member.id)

        let fetched = WatchHistory(
            member: member,
            diary: diary,
            watchlist: watchlist,
            lists: lists,
            statistics: statistics
        )

        onProgress?(.merging)
        let existing = try await store.loadHistory(username: member.username)
        let merged = HistoryMerge.mergeHistory(existing: existing, fetched: fetched)

        onProgress?(.saving)
        try await store.save(merged)

        onProgress?(.finished)
        return merged
    }
}
