import Foundation

// MARK: - Wire DTOs
//
// Internal Codable types that mirror Letterboxd's documented JSON. Kept
// defensively optional-tolerant: any field the API may omit is optional so a
// single missing value never fails a whole decode. Mapping to MiseCore lives in
// `Mappers.swift`.
//
// TODO: verify against live API — field names, nesting, and nullability below
// are based on the documented Letterboxd API v0 and must be confirmed via the
// live spike (mise-smoke).

/// A generic image/avatar with multiple sizes; Letterboxd returns `{ sizes: [...] }`.
struct ImageDTO: Decodable, Sendable {
    struct Size: Decodable, Sendable {
        let width: Int?
        let height: Int?
        let url: String?
    }
    let sizes: [Size]?

    /// The largest available size's URL (by width).
    var bestURL: URL? {
        let best = (sizes ?? []).max { ($0.width ?? 0) < ($1.width ?? 0) }
        return (best?.url).flatMap(URL.init(string:))
    }
}

/// A link to an external service, e.g. `{ "type": "tmdb", "id": "496243", "url": ... }`.
struct LinkDTO: Decodable, Sendable {
    let type: String?
    let id: String?
    let url: String?
}

/// `member/{id}` and embedded member summaries.
struct MemberDTO: Decodable, Sendable {
    let id: String?
    let username: String?
    let displayName: String?
    let avatar: ImageDTO?
}

/// Wrapper around `/search` / member-search responses.
struct MemberSearchResponseDTO: Decodable, Sendable {
    struct Item: Decodable, Sendable {
        let type: String?
        let member: MemberDTO?
    }
    let items: [Item]?
}

/// `member/{id}/statistics`.
struct MemberStatisticsDTO: Decodable, Sendable {
    struct Counts: Decodable, Sendable {
        let watches: Int?
        let diaryEntries: Int?
        let lists: Int?
        let followers: Int?
        let following: Int?
    }
    /// One bar of the ratings histogram. `rating` is in stars (0.5...5.0).
    struct RatingsHistogramBar: Decodable, Sendable {
        let rating: Double?
        let count: Int?
    }
    let counts: Counts?
    let ratingsHistogram: [RatingsHistogramBar]?
}

/// A film genre.
struct GenreDTO: Decodable, Sendable {
    let id: String?
    let name: String?
}

/// A film contributor (director, actor, etc.).
struct ContributorDTO: Decodable, Sendable {
    let id: String?
    let name: String?
    let characterName: String?
}

/// A summary of contributions of one type, e.g. `{ "type": "Director", "contributors": [...] }`.
struct ContributionDTO: Decodable, Sendable {
    let type: String?
    let contributors: [ContributorDTO]?
}

/// A country / language reference, e.g. `{ "code": "US", "name": "USA" }`.
struct CountryDTO: Decodable, Sendable {
    let code: String?
    let name: String?
}

/// `film/{id}` and embedded film summaries.
struct FilmDTO: Decodable, Sendable {
    let id: String?
    let name: String?
    let releaseYear: Int?
    let runTime: Int?
    let genres: [GenreDTO]?
    let contributions: [ContributionDTO]?
    let countries: [CountryDTO]?
    let languages: [CountryDTO]?
    let poster: ImageDTO?
    let rating: Double?            // Letterboxd community average (stars)
    let links: [LinkDTO]?

    /// The TMDB numeric id, parsed from the `tmdb` link.
    var tmdbID: Int? {
        guard let tmdb = (links ?? []).first(where: { $0.type?.lowercased() == "tmdb" }),
              let idString = tmdb.id else { return nil }
        return Int(idString)
    }

    /// The Letterboxd canonical URL, from the `letterboxd` link if present.
    var letterboxdURL: URL? {
        let link = (links ?? []).first { $0.type?.lowercased() == "letterboxd" }
        return (link?.url).flatMap(URL.init(string:))
    }
}

/// Wrapper for `/films/search` style responses.
struct FilmSearchResponseDTO: Decodable, Sendable {
    struct Item: Decodable, Sendable {
        let type: String?
        let film: FilmDTO?
    }
    let items: [Item]?
}

/// A diary/log entry from `/log-entries`.
struct LogEntryDTO: Decodable, Sendable {
    struct DiaryDetails: Decodable, Sendable {
        let diaryDate: String?     // ISO yyyy-MM-dd
        let rewatch: Bool?
    }
    struct Review: Decodable, Sendable {
        let text: String?
    }
    let id: String?
    let film: FilmDTO?
    let diaryDetails: DiaryDetails?
    let rating: Double?            // stars 0.5...5.0
    let like: Bool?
    let review: Review?
    let tags2: [TagDTO]?
    let whenCreated: String?       // ISO8601 timestamp
}

struct TagDTO: Decodable, Sendable {
    let displayTag: String?
    let tag: String?
}

/// `/log-entries` paged response.
struct LogEntriesResponseDTO: Decodable, Sendable {
    let items: [LogEntryDTO]?
    let next: String?
}

/// An entry on `member/{id}/watchlist` (a film summary wrapper).
struct WatchlistResponseDTO: Decodable, Sendable {
    let items: [FilmDTO]?
    let next: String?
}

/// `/lists`.
struct ListDTO: Decodable, Sendable {
    struct Entry: Decodable, Sendable {
        let film: FilmDTO?
    }
    let id: String?
    let name: String?
    let description: String?
    let ranked: Bool?
    let entries: [Entry]?
}

struct ListsResponseDTO: Decodable, Sendable {
    let items: [ListDTO]?
    let next: String?
}
