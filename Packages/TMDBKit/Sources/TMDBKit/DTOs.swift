import Foundation

/// Codable DTOs mirroring the real TMDB JSON shapes. Internal — callers see the
/// public domain models in `Models.swift`.

struct MovieDTO: Decodable {
    let id: Int
    let title: String
    let posterPath: String?
    let runtime: Int?
    let releaseDate: String?
    let genres: [GenreDTO]?

    enum CodingKeys: String, CodingKey {
        case id, title, runtime, genres
        case posterPath = "poster_path"
        case releaseDate = "release_date"
    }

    func toModel() -> TMDBMovie {
        TMDBMovie(
            id: id,
            title: title,
            posterPath: posterPath,
            runtime: runtime,
            releaseDate: releaseDate,
            genres: (genres ?? []).map(\.name)
        )
    }
}

struct GenreDTO: Decodable {
    let id: Int
    let name: String
}

struct SearchResponseDTO: Decodable {
    let results: [SearchResultDTO]
}

struct SearchResultDTO: Decodable {
    let id: Int
    let title: String
    let posterPath: String?
    let releaseDate: String?

    enum CodingKeys: String, CodingKey {
        case id, title
        case posterPath = "poster_path"
        case releaseDate = "release_date"
    }

    func toModel() -> TMDBSearchResult {
        TMDBSearchResult(
            id: id,
            title: title,
            releaseYear: Self.year(from: releaseDate),
            posterPath: posterPath
        )
    }

    /// Parses a leading 4-digit year from a TMDB "YYYY-MM-DD" date; `nil` if absent.
    static func year(from date: String?) -> Int? {
        guard let date, date.count >= 4 else { return nil }
        return Int(date.prefix(4))
    }
}

struct WatchProvidersResponseDTO: Decodable {
    let id: Int
    let results: [String: RegionProvidersDTO]
}

struct RegionProvidersDTO: Decodable {
    let flatrate: [ProviderDTO]?
    let rent: [ProviderDTO]?
    let buy: [ProviderDTO]?

    /// Flattens the region's per-kind buckets into tagged ``WatchProvider`` values,
    /// preserving TMDB's `display_priority` ordering within each kind.
    func providers() -> [WatchProvider] {
        func map(_ list: [ProviderDTO]?, _ kind: WatchProvider.ProviderKind) -> [WatchProvider] {
            (list ?? [])
                .sorted { ($0.displayPriority ?? .max) < ($1.displayPriority ?? .max) }
                .map { WatchProvider(kind: kind, providerName: $0.providerName, logoPath: $0.logoPath) }
        }
        return map(flatrate, .flatrate) + map(rent, .rent) + map(buy, .buy)
    }
}

struct ProviderDTO: Decodable {
    let providerName: String
    let logoPath: String?
    let displayPriority: Int?

    enum CodingKeys: String, CodingKey {
        case providerName = "provider_name"
        case logoPath = "logo_path"
        case displayPriority = "display_priority"
    }
}
