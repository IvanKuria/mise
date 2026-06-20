import Foundation
import SwiftData
import MiseCore

/// SwiftData @Model classes mapping to/from MiseCore values.
///
/// The adapter is intentionally THIN: each model stores the small set of columns
/// worth indexing/faceting (id, title, year, rating, dates, flags) plus a Codable
/// blob of the full embedded `Film` so reconstruction is lossless without a sprawl
/// of relationship tables. All merge/ordering correctness stays in `HistoryMerge`.

@Model
public final class SDMember {
    @Attribute(.unique) public var username: String
    public var memberID: String
    public var displayName: String
    public var avatarURLString: String?

    // Statistics (flattened; nil-able sentinel via hasStatistics).
    public var hasStatistics: Bool
    public var watchedFilmCount: Int
    public var diaryEntryCount: Int
    public var listCount: Int
    public var followerCount: Int
    public var followingCount: Int
    /// JSON-encoded `[Int: Int]` histogram.
    public var ratingsHistogramData: Data

    @Relationship(deleteRule: .cascade, inverse: \SDDiaryEntry.member)
    public var diary: [SDDiaryEntry]
    @Relationship(deleteRule: .cascade, inverse: \SDWatchlistItem.member)
    public var watchlist: [SDWatchlistItem]
    @Relationship(deleteRule: .cascade, inverse: \SDList.member)
    public var lists: [SDList]

    public init(
        username: String,
        memberID: String,
        displayName: String,
        avatarURLString: String?,
        hasStatistics: Bool,
        watchedFilmCount: Int,
        diaryEntryCount: Int,
        listCount: Int,
        followerCount: Int,
        followingCount: Int,
        ratingsHistogramData: Data,
        diary: [SDDiaryEntry] = [],
        watchlist: [SDWatchlistItem] = [],
        lists: [SDList] = []
    ) {
        self.username = username
        self.memberID = memberID
        self.displayName = displayName
        self.avatarURLString = avatarURLString
        self.hasStatistics = hasStatistics
        self.watchedFilmCount = watchedFilmCount
        self.diaryEntryCount = diaryEntryCount
        self.listCount = listCount
        self.followerCount = followerCount
        self.followingCount = followingCount
        self.ratingsHistogramData = ratingsHistogramData
        self.diary = diary
        self.watchlist = watchlist
        self.lists = lists
    }
}

@Model
public final class SDDiaryEntry {
    @Attribute(.unique) public var id: String
    public var filmID: String
    public var filmName: String
    public var releaseYear: Int?
    public var watchedDate: Date?
    public var loggedDate: Date?
    /// Rating half-stars, 0 when unrated.
    public var ratingHalfStars: Int
    public var isRewatch: Bool
    public var isLiked: Bool
    public var review: String?
    /// JSON-encoded full `DiaryEntry`.
    public var payload: Data
    public var member: SDMember?

    public init(
        id: String,
        filmID: String,
        filmName: String,
        releaseYear: Int?,
        watchedDate: Date?,
        loggedDate: Date?,
        ratingHalfStars: Int,
        isRewatch: Bool,
        isLiked: Bool,
        review: String?,
        payload: Data
    ) {
        self.id = id
        self.filmID = filmID
        self.filmName = filmName
        self.releaseYear = releaseYear
        self.watchedDate = watchedDate
        self.loggedDate = loggedDate
        self.ratingHalfStars = ratingHalfStars
        self.isRewatch = isRewatch
        self.isLiked = isLiked
        self.review = review
        self.payload = payload
    }
}

@Model
public final class SDWatchlistItem {
    @Attribute(.unique) public var filmID: String
    public var filmName: String
    public var releaseYear: Int?
    public var addedDate: Date?
    /// JSON-encoded full `WatchlistItem`.
    public var payload: Data
    public var member: SDMember?

    public init(
        filmID: String,
        filmName: String,
        releaseYear: Int?,
        addedDate: Date?,
        payload: Data
    ) {
        self.filmID = filmID
        self.filmName = filmName
        self.releaseYear = releaseYear
        self.addedDate = addedDate
        self.payload = payload
    }
}

@Model
public final class SDList {
    @Attribute(.unique) public var id: String
    public var name: String
    public var listDescription: String?
    public var ranked: Bool
    public var filmCount: Int
    /// JSON-encoded full `FilmList`.
    public var payload: Data
    public var member: SDMember?

    public init(
        id: String,
        name: String,
        listDescription: String?,
        ranked: Bool,
        filmCount: Int,
        payload: Data
    ) {
        self.id = id
        self.name = name
        self.listDescription = listDescription
        self.ranked = ranked
        self.filmCount = filmCount
        self.payload = payload
    }
}
