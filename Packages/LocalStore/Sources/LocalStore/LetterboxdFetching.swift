import Foundation
import MiseCore

/// The read surface LocalStore needs from a Letterboxd API client.
///
/// Decouples the sync engine from `LetterboxdKit` so it can be exercised in tests
/// with a mock and no network. `LetterboxdKit.LetterboxdClient` conforms to this
/// *structurally* — its read methods have the exact signatures and MiseCore return
/// types below, so the app can simply declare the conformance:
///
/// ```swift
/// extension LetterboxdClient: LetterboxdFetching {}
/// ```
///
/// (LetterboxdKit is not modified here — this protocol is declared only in
/// LocalStore. The default arguments on the client's `logEntries` are compatible
/// with the protocol requirement.)
public protocol LetterboxdFetching: Sendable {
    /// Resolve a handle to a member summary.
    func member(username: String) async throws -> MemberSummary

    /// Aggregate counts and ratings histogram for a member.
    func statistics(memberID: String) async throws -> MemberStatistics

    /// Diary / log entries for a member.
    func logEntries(memberID: String, perPage: Int, cursor: String?) async throws -> [DiaryEntry]

    /// A member's watchlist.
    func watchlist(memberID: String) async throws -> [WatchlistItem]

    /// A member's lists.
    func lists(memberID: String) async throws -> [FilmList]
}
