import Foundation
import SwiftData
import MiseCore

/// Thin SwiftData persistence adapter for synced watch history.
///
/// Maps MiseCore values to/from the `@Model` classes and exposes a small
/// `HistoryStoring` API. All correctness/ordering lives in `HistoryMerge`; this
/// type only does encode/decode and upsert plumbing.
public final class LibraryStore: HistoryStoring {
    private let container: ModelContainer

    /// Build on an existing container (e.g. the app's shared one).
    public init(container: ModelContainer) {
        self.container = container
    }

    /// Convenience initializer. Pass `inMemory: true` for tests.
    public convenience init(inMemory: Bool = false) throws {
        let schema = Schema(LibraryStore.schemaModels)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        let container = try ModelContainer(for: schema, configurations: configuration)
        self.init(container: container)
    }

    /// The model types backing this store, for `ModelContainer` construction.
    public static let schemaModels: [any PersistentModel.Type] = [
        SDMember.self, SDDiaryEntry.self, SDWatchlistItem.self, SDList.self,
    ]

    // MARK: - HistoryStoring

    public func loadHistory(username: String) async throws -> WatchHistory? {
        let context = ModelContext(container)
        guard let member = try Self.fetchMember(username: username, in: context) else { return nil }
        return try Self.toWatchHistory(member)
    }

    public func save(_ history: WatchHistory) async throws {
        let context = ModelContext(container)
        let username = history.member.username

        let member: SDMember
        if let existing = try Self.fetchMember(username: username, in: context) {
            member = existing
            // Explicitly delete existing children before re-inserting the merged set.
            for child in existing.diary { context.delete(child) }
            for child in existing.watchlist { context.delete(child) }
            for child in existing.lists { context.delete(child) }
            member.diary = []
            member.watchlist = []
            member.lists = []
        } else {
            member = SDMember(
                username: username,
                memberID: history.member.id,
                displayName: history.member.displayName,
                avatarURLString: history.member.avatarURL?.absoluteString,
                hasStatistics: false,
                watchedFilmCount: 0, diaryEntryCount: 0, listCount: 0,
                followerCount: 0, followingCount: 0,
                ratingsHistogramData: Self.encodeHistogram([:])
            )
            context.insert(member)
        }

        // Member + statistics.
        member.memberID = history.member.id
        member.displayName = history.member.displayName
        member.avatarURLString = history.member.avatarURL?.absoluteString
        if let stats = history.statistics {
            member.hasStatistics = true
            member.watchedFilmCount = stats.watchedFilmCount
            member.diaryEntryCount = stats.diaryEntryCount
            member.listCount = stats.listCount
            member.followerCount = stats.followerCount
            member.followingCount = stats.followingCount
            member.ratingsHistogramData = Self.encodeHistogram(stats.ratingsHistogram)
        } else {
            member.hasStatistics = false
        }

        for entry in history.diary {
            let sd = SDDiaryEntry(
                id: entry.id,
                filmID: entry.film.id,
                filmName: entry.film.name,
                releaseYear: entry.film.releaseYear,
                watchedDate: entry.watchedDate,
                loggedDate: entry.loggedDate,
                ratingHalfStars: entry.rating?.halfStars ?? 0,
                isRewatch: entry.isRewatch,
                isLiked: entry.isLiked,
                review: entry.review,
                payload: Self.encode(entry)
            )
            sd.member = member
            context.insert(sd)
        }
        for item in history.watchlist {
            let sd = SDWatchlistItem(
                filmID: item.film.id,
                filmName: item.film.name,
                releaseYear: item.film.releaseYear,
                addedDate: item.addedDate,
                payload: Self.encode(item)
            )
            sd.member = member
            context.insert(sd)
        }
        for list in history.lists {
            let sd = SDList(
                id: list.id,
                name: list.name,
                listDescription: list.description,
                ranked: list.ranked,
                filmCount: list.films.count,
                payload: Self.encode(list)
            )
            sd.member = member
            context.insert(sd)
        }

        try context.save()
    }

    // MARK: - Mapping

    private static func fetchMember(username: String, in context: ModelContext) throws -> SDMember? {
        var descriptor = FetchDescriptor<SDMember>(
            predicate: #Predicate { $0.username == username }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private static func toWatchHistory(_ member: SDMember) throws -> WatchHistory {
        let summary = MemberSummary(
            id: member.memberID,
            username: member.username,
            displayName: member.displayName,
            avatarURL: member.avatarURLString.flatMap(URL.init(string:))
        )
        let statistics: MemberStatistics? = member.hasStatistics
            ? MemberStatistics(
                watchedFilmCount: member.watchedFilmCount,
                diaryEntryCount: member.diaryEntryCount,
                listCount: member.listCount,
                followerCount: member.followerCount,
                followingCount: member.followingCount,
                ratingsHistogram: Self.decodeHistogram(member.ratingsHistogramData)
            )
            : nil

        let diary = try member.diary.map { try decode(DiaryEntry.self, from: $0.payload) }
        let watchlist = try member.watchlist.map { try decode(WatchlistItem.self, from: $0.payload) }
        let lists = try member.lists.map { try decode(FilmList.self, from: $0.payload) }

        // Reapply the canonical ordering so loaded history matches merge output
        // regardless of relationship iteration order.
        return WatchHistory(
            member: summary,
            diary: HistoryMerge.mergeDiary(existing: [], fetched: diary),
            watchlist: HistoryMerge.mergeWatchlist(existing: [], fetched: watchlist),
            lists: HistoryMerge.mergeLists(existing: [], fetched: lists),
            statistics: statistics
        )
    }

    // MARK: - Codable helpers

    private static func encode<T: Encodable>(_ value: T) -> Data {
        (try? JSONEncoder().encode(value)) ?? Data()
    }

    private static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try JSONDecoder().decode(type, from: data)
    }

    /// `[Int: Int]` doesn't round-trip through JSON with integer keys, so encode
    /// the histogram as a string-keyed dictionary.
    private static func encodeHistogram(_ histogram: [Int: Int]) -> Data {
        let stringKeyed = Dictionary(uniqueKeysWithValues: histogram.map { (String($0.key), $0.value) })
        return (try? JSONEncoder().encode(stringKeyed)) ?? Data()
    }

    private static func decodeHistogram(_ data: Data) -> [Int: Int] {
        guard let stringKeyed = try? JSONDecoder().decode([String: Int].self, from: data) else { return [:] }
        return Dictionary(uniqueKeysWithValues: stringKeyed.compactMap { key, value in
            Int(key).map { ($0, value) }
        })
    }
}
