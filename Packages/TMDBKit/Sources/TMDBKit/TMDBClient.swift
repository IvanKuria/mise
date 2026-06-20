import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// An async client for The Movie Database (TMDB).
///
/// Used for high-res posters, supplemental metadata, and streaming / watch
/// providers (JustWatch data) keyed by TMDB id.
public actor TMDBClient {
    private static let baseURL = URL(string: "https://api.themoviedb.org/3/")!
    private static let imageBaseURL = URL(string: "https://image.tmdb.org/t/p/")!

    private let apiKey: String
    private let useBearerToken: Bool
    private let transport: any TMDBTransport
    private let decoder = JSONDecoder()

    /// - Parameters:
    ///   - apiKey: A v4 bearer token (default) or a v3 `api_key`.
    ///   - useBearerToken: When `true` (default), the key is sent as an
    ///     `Authorization: Bearer …` header. When `false`, it is sent as an
    ///     `api_key` query parameter (v3 style).
    ///   - transport: The network transport. Defaults to ``URLSessionTMDBTransport``.
    public init(
        apiKey: String,
        useBearerToken: Bool = true,
        transport: any TMDBTransport = URLSessionTMDBTransport()
    ) {
        self.apiKey = apiKey
        self.useBearerToken = useBearerToken
        self.transport = transport
    }

    // MARK: - Endpoints

    /// GET /movie/{id}
    public func movie(tmdbID: Int) async throws -> TMDBMovie {
        let request = makeRequest(path: "movie/\(tmdbID)")
        let data = try await transport.data(for: request)
        return try decode(MovieDTO.self, from: data).toModel()
    }

    /// GET /movie/{id}/watch/providers — providers for `region`, tagged by kind.
    /// Returns an empty array when the region is absent.
    public func watchProviders(tmdbID: Int, region: String) async throws -> [WatchProvider] {
        let request = makeRequest(path: "movie/\(tmdbID)/watch/providers")
        let data = try await transport.data(for: request)
        let response = try decode(WatchProvidersResponseDTO.self, from: data)
        return response.results[region]?.providers() ?? []
    }

    /// Builds an image URL: https://image.tmdb.org/t/p/{size}{path}. Returns `nil`
    /// for an empty path.
    public func posterURL(path: String, size: String) -> URL? {
        guard !path.isEmpty else { return nil }
        return URL(string: "\(size)\(path)", relativeTo: Self.imageBaseURL)?.absoluteURL
    }

    // MARK: - Helpers

    private func makeRequest(path: String) -> URLRequest {
        var url = URL(string: path, relativeTo: Self.baseURL)!.absoluteURL
        if !useBearerToken {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            var items = components.queryItems ?? []
            items.append(URLQueryItem(name: "api_key", value: apiKey))
            components.queryItems = items
            url = components.url ?? url
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if useBearerToken {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw TMDBError.decoding(error)
        }
    }
}
