import Foundation

/// A person credited on a film (director, cast member, writer, etc.).
public struct Person: Hashable, Codable, Sendable, Identifiable {
    public let id: String
    public let name: String
    /// For cast: the character played, if known.
    public let characterName: String?

    public init(id: String, name: String, characterName: String? = nil) {
        self.id = id
        self.name = name
        self.characterName = characterName
    }
}

/// A film genre as defined by Letterboxd.
public struct Genre: Hashable, Codable, Sendable, Identifiable {
    public let id: String
    public let name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

/// A film. The canonical id is the Letterboxd film id; `tmdbID` links to TMDB
/// for posters, richer metadata, and streaming providers.
public struct Film: Hashable, Codable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let releaseYear: Int?
    public let runtimeMinutes: Int?
    public let genres: [Genre]
    public let directors: [Person]
    public let cast: [Person]
    public let countries: [String]
    public let languages: [String]
    public let tmdbID: Int?
    public let posterURL: URL?
    /// Letterboxd's community average rating in stars (0.5...5.0), if known.
    public let letterboxdAverageRating: Double?
    public let letterboxdURL: URL?

    public init(
        id: String,
        name: String,
        releaseYear: Int? = nil,
        runtimeMinutes: Int? = nil,
        genres: [Genre] = [],
        directors: [Person] = [],
        cast: [Person] = [],
        countries: [String] = [],
        languages: [String] = [],
        tmdbID: Int? = nil,
        posterURL: URL? = nil,
        letterboxdAverageRating: Double? = nil,
        letterboxdURL: URL? = nil
    ) {
        self.id = id
        self.name = name
        self.releaseYear = releaseYear
        self.runtimeMinutes = runtimeMinutes
        self.genres = genres
        self.directors = directors
        self.cast = cast
        self.countries = countries
        self.languages = languages
        self.tmdbID = tmdbID
        self.posterURL = posterURL
        self.letterboxdAverageRating = letterboxdAverageRating
        self.letterboxdURL = letterboxdURL
    }

    /// The decade of the film's release, e.g. 1987 -> 1980. `nil` if year unknown.
    public var decade: Int? {
        guard let releaseYear else { return nil }
        return releaseYear - (releaseYear % 10)
    }
}
