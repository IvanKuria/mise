import Foundation

/// A Letterboxd member, identified by the stable member id; `username` is the handle.
public struct MemberSummary: Hashable, Codable, Sendable, Identifiable {
    public let id: String
    public let username: String
    public let displayName: String
    public let avatarURL: URL?

    public init(id: String, username: String, displayName: String, avatarURL: URL? = nil) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.avatarURL = avatarURL
    }
}

/// Aggregate counts and the ratings histogram for a member, as exposed by the
/// `member/{id}/statistics` endpoint. The histogram maps half-stars (1...10) to
/// the number of films the member gave that rating.
public struct MemberStatistics: Hashable, Codable, Sendable {
    public let watchedFilmCount: Int
    public let diaryEntryCount: Int
    public let listCount: Int
    public let followerCount: Int
    public let followingCount: Int
    /// half-stars (1...10) -> count
    public let ratingsHistogram: [Int: Int]

    public init(
        watchedFilmCount: Int = 0,
        diaryEntryCount: Int = 0,
        listCount: Int = 0,
        followerCount: Int = 0,
        followingCount: Int = 0,
        ratingsHistogram: [Int: Int] = [:]
    ) {
        self.watchedFilmCount = watchedFilmCount
        self.diaryEntryCount = diaryEntryCount
        self.listCount = listCount
        self.followerCount = followerCount
        self.followingCount = followingCount
        self.ratingsHistogram = ratingsHistogram
    }
}
