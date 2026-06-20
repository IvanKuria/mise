import Foundation
import Testing
@testable import TMDBKit

@Suite("TMDBClient")
struct TMDBClientTests {

    // MARK: - movie decoding

    @Test("decodes a /movie/{id} response into TMDBMovie")
    func decodesMovie() async throws {
        let client = TMDBClient(apiKey: "test-token", transport: MockTransport(.success(Fixtures.movie)))

        let movie = try await client.movie(tmdbID: 496243)

        #expect(movie.id == 496243)
        #expect(movie.title == "Parasite")
        #expect(movie.posterPath == "/7IiTTgloJzvGI1TAYymCfbfl3vT.jpg")
        #expect(movie.runtime == 133)
        #expect(movie.releaseDate == "2019-05-30")
        #expect(movie.genres == ["Comedy", "Thriller", "Drama"])
    }

    @Test("sends bearer Authorization header and hits the right path")
    func movieRequestIsAuthorized() async throws {
        let transport = MockTransport(.success(Fixtures.movie))
        let client = TMDBClient(apiKey: "test-token", transport: transport)

        _ = try await client.movie(tmdbID: 496243)

        let request = try #require(transport.recordedRequests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-token")
        #expect(request.url?.absoluteString == "https://api.themoviedb.org/3/movie/496243")
    }

    // MARK: - watch providers

    @Test("parses watch providers for a region tagged by kind")
    func parsesWatchProviders() async throws {
        let client = TMDBClient(apiKey: "k", transport: MockTransport(.success(Fixtures.watchProviders)))

        let providers = try await client.watchProviders(tmdbID: 496243, region: "US")

        #expect(providers.count == 4)

        let flatrate = providers.filter { $0.kind == .flatrate }
        #expect(flatrate.map(\.providerName) == ["Netflix", "Hulu"])

        let rent = providers.filter { $0.kind == .rent }
        #expect(rent.map(\.providerName) == ["Apple TV"])

        let buy = providers.filter { $0.kind == .buy }
        #expect(buy.map(\.providerName) == ["Google Play Movies"])

        let netflix = try #require(providers.first { $0.providerName == "Netflix" })
        #expect(netflix.logoPath == "/peURlLlr8jggOwK53fJ5wdQl05.jpg")
    }

    @Test("returns no providers when the region is missing")
    func missingRegionReturnsEmpty() async throws {
        let client = TMDBClient(apiKey: "k", transport: MockTransport(.success(Fixtures.watchProviders)))

        let providers = try await client.watchProviders(tmdbID: 496243, region: "FR")

        #expect(providers.isEmpty)
    }

    @Test("returns no providers when results object is empty")
    func emptyResultsReturnsEmpty() async throws {
        let client = TMDBClient(apiKey: "k", transport: MockTransport(.success(Fixtures.watchProvidersEmpty)))

        let providers = try await client.watchProviders(tmdbID: 496243, region: "US")

        #expect(providers.isEmpty)
    }

    @Test("watch providers request targets the right path")
    func watchProvidersPath() async throws {
        let transport = MockTransport(.success(Fixtures.watchProviders))
        let client = TMDBClient(apiKey: "k", transport: transport)

        _ = try await client.watchProviders(tmdbID: 496243, region: "US")

        let request = try #require(transport.recordedRequests.first)
        #expect(request.url?.absoluteString == "https://api.themoviedb.org/3/movie/496243/watch/providers")
    }

    // MARK: - search

    @Test("decodes a /search/movie response into TMDBSearchResults")
    func decodesSearch() async throws {
        let client = TMDBClient(apiKey: "k", transport: MockTransport(.success(Fixtures.searchMovie)))

        let results = try await client.search(title: "Parasite", year: nil)

        #expect(results.count == 3)
        #expect(results[0] == TMDBSearchResult(
            id: 496243,
            title: "Parasite",
            releaseYear: 2019,
            posterPath: "/7IiTTgloJzvGI1TAYymCfbfl3vT.jpg"
        ))
        #expect(results[1].id == 61225)
        #expect(results[1].releaseYear == 1982)
        // Empty release_date parses to nil year; null poster_path stays nil.
        #expect(results[2].releaseYear == nil)
        #expect(results[2].posterPath == nil)
    }

    @Test("returns no results for an empty search response")
    func searchEmptyReturnsEmpty() async throws {
        let client = TMDBClient(apiKey: "k", transport: MockTransport(.success(Fixtures.searchEmpty)))

        let results = try await client.search(title: "Nonexistent Film", year: 1999)

        #expect(results.isEmpty)
    }

    @Test("search with a year includes primary_release_year and encodes the query")
    func searchRequestWithYear() async throws {
        let transport = MockTransport(.success(Fixtures.searchMovie))
        let client = TMDBClient(apiKey: "k", transport: transport)

        _ = try await client.search(title: "The Florida Project", year: 2017)

        let request = try #require(transport.recordedRequests.first)
        let components = URLComponents(url: try #require(request.url), resolvingAgainstBaseURL: false)
        let items = try #require(components?.queryItems)
        #expect(request.url?.path == "/3/search/movie")
        #expect(items.contains(URLQueryItem(name: "query", value: "The Florida Project")))
        #expect(items.contains(URLQueryItem(name: "primary_release_year", value: "2017")))
    }

    @Test("search without a year omits primary_release_year")
    func searchRequestWithoutYear() async throws {
        let transport = MockTransport(.success(Fixtures.searchMovie))
        let client = TMDBClient(apiKey: "k", transport: transport)

        _ = try await client.search(title: "Parasite", year: nil)

        let request = try #require(transport.recordedRequests.first)
        let components = URLComponents(url: try #require(request.url), resolvingAgainstBaseURL: false)
        let items = components?.queryItems ?? []
        #expect(items.contains(URLQueryItem(name: "query", value: "Parasite")))
        #expect(!items.contains { $0.name == "primary_release_year" })
    }

    // MARK: - posterURL

    @Test("builds a poster URL from size and path")
    func buildsPosterURL() async throws {
        let client = TMDBClient(apiKey: "k", transport: MockTransport(.success(Data())))

        let url = await client.posterURL(path: "/7IiTTgloJzvGI1TAYymCfbfl3vT.jpg", size: "w500")

        #expect(url?.absoluteString == "https://image.tmdb.org/t/p/w500/7IiTTgloJzvGI1TAYymCfbfl3vT.jpg")
    }

    @Test("returns nil poster URL for an empty path")
    func posterURLNilForEmptyPath() async throws {
        let client = TMDBClient(apiKey: "k", transport: MockTransport(.success(Data())))

        let url = await client.posterURL(path: "", size: "w500")

        #expect(url == nil)
    }

    // MARK: - errors

    @Test("throws on a non-2xx response")
    func throwsOnNon2xx() async throws {
        let transport = MockTransport(.status(401, Fixtures.errorBody))
        let client = TMDBClient(apiKey: "bad", transport: transport)

        await #expect(throws: TMDBError.self) {
            _ = try await client.movie(tmdbID: 496243)
        }
    }

    @Test("throws a decoding error on malformed JSON")
    func throwsOnMalformedJSON() async throws {
        let transport = MockTransport(.success(Data("not json".utf8)))
        let client = TMDBClient(apiKey: "k", transport: transport)

        await #expect(throws: TMDBError.self) {
            _ = try await client.movie(tmdbID: 496243)
        }
    }
}
