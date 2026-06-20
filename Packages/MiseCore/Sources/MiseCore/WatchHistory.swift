import Foundation

/// A single diary/log entry: a film the member logged, optionally with a rating,
/// review, watched date, and rewatch/like flags. The `Film` is embedded so the
/// pure engines can operate on `[DiaryEntry]` without a separate lookup.
public struct DiaryEntry: Hashable, Codable, Sendable, Identifiable {
    public let id: String
    public let film: Film
    /// The date the film was watched (diary date), if recorded.
    public let watchedDate: Date?
    /// The date the entry was logged on Letterboxd.
    public let loggedDate: Date?
    public let rating: Rating?
    public let isRewatch: Bool
    public let isLiked: Bool
    public let review: String?
    public let tags: [String]

    public init(
        id: String,
        film: Film,
        watchedDate: Date? = nil,
        loggedDate: Date? = nil,
        rating: Rating? = nil,
        isRewatch: Bool = false,
        isLiked: Bool = false,
        review: String? = nil,
        tags: [String] = []
    ) {
        self.id = id
        self.film = film
        self.watchedDate = watchedDate
        self.loggedDate = loggedDate
        self.rating = rating
        self.isRewatch = isRewatch
        self.isLiked = isLiked
        self.review = review
        self.tags = tags
    }

    public var hasReview: Bool { !(review ?? "").isEmpty }
}

/// An entry on a member's watchlist.
public struct WatchlistItem: Hashable, Codable, Sendable, Identifiable {
    public var id: String { film.id }
    public let film: Film
    public let addedDate: Date?

    public init(film: Film, addedDate: Date? = nil) {
        self.film = film
        self.addedDate = addedDate
    }
}

/// A member-created list of films (ordered if `ranked`).
public struct FilmList: Hashable, Codable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let description: String?
    public let ranked: Bool
    public let films: [Film]

    public init(id: String, name: String, description: String? = nil, ranked: Bool = false, films: [Film] = []) {
        self.id = id
        self.name = name
        self.description = description
        self.ranked = ranked
        self.films = films
    }
}

/// The full, synced public history for one member — the input to the analytics
/// and recommender engines.
public struct WatchHistory: Hashable, Codable, Sendable {
    public let member: MemberSummary
    public let diary: [DiaryEntry]
    public let watchlist: [WatchlistItem]
    public let lists: [FilmList]
    public let statistics: MemberStatistics?

    public init(
        member: MemberSummary,
        diary: [DiaryEntry] = [],
        watchlist: [WatchlistItem] = [],
        lists: [FilmList] = [],
        statistics: MemberStatistics? = nil
    ) {
        self.member = member
        self.diary = diary
        self.watchlist = watchlist
        self.lists = lists
        self.statistics = statistics
    }
}
