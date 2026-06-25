import Foundation

/// A film's core supplemental metadata from TMDB.
public struct TMDBMovie: Sendable, Equatable {
    public let id: Int
    public let title: String
    public let posterPath: String?
    public let runtime: Int?
    public let releaseDate: String?
    public let genres: [String]
    public let overview: String?
    public let tagline: String?

    public init(
        id: Int,
        title: String,
        posterPath: String?,
        runtime: Int?,
        releaseDate: String?,
        genres: [String],
        overview: String? = nil,
        tagline: String? = nil
    ) {
        self.id = id
        self.title = title
        self.posterPath = posterPath
        self.runtime = runtime
        self.releaseDate = releaseDate
        self.genres = genres
        self.overview = overview
        self.tagline = tagline
    }
}

/// A single result from a TMDB movie search.
public struct TMDBSearchResult: Sendable, Equatable {
    public let id: Int
    public let title: String
    /// The release year parsed from TMDB's `release_date` (e.g. "2019-05-30" -> 2019).
    /// `nil` when the date is absent or unparseable.
    public let releaseYear: Int?
    public let posterPath: String?

    public init(id: Int, title: String, releaseYear: Int?, posterPath: String?) {
        self.id = id
        self.title = title
        self.releaseYear = releaseYear
        self.posterPath = posterPath
    }
}

/// A streaming / watch provider for a film in a given region (JustWatch data via TMDB).
public struct WatchProvider: Sendable, Equatable {
    /// How the film is available from this provider.
    public enum ProviderKind: String, Sendable, Equatable {
        case flatrate
        case rent
        case buy
    }

    public let kind: ProviderKind
    public let providerName: String
    public let logoPath: String?

    public init(kind: ProviderKind, providerName: String, logoPath: String?) {
        self.kind = kind
        self.providerName = providerName
        self.logoPath = logoPath
    }
}
