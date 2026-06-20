import Foundation
import MiseCore

/// The persistence surface the `SyncEngine` needs.
///
/// `LibraryStore` (the SwiftData adapter) conforms to this. Tests can also use a
/// lightweight in-memory conformer, so the sync/merge flow is testable without
/// SwiftData hosting.
public protocol HistoryStoring: Sendable {
    /// The stored history for a username, or nil if never synced.
    func loadHistory(username: String) async throws -> WatchHistory?

    /// Persist (upsert) the given history, keyed by `member.username`.
    func save(_ history: WatchHistory) async throws
}
