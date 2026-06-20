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
