import Foundation

/// A film's core supplemental metadata from TMDB.
public struct TMDBMovie: Sendable, Equatable {
    public let id: Int
    public let title: String
    public let posterPath: String?
    public let runtime: Int?
    public let releaseDate: String?
    public let genres: [String]

    public init(
        id: Int,
        title: String,
        posterPath: String?,
        runtime: Int?,
        releaseDate: String?,
        genres: [String]
    ) {
        self.id = id
        self.title = title
        self.posterPath = posterPath
        self.runtime = runtime
        self.releaseDate = releaseDate
        self.genres = genres
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
