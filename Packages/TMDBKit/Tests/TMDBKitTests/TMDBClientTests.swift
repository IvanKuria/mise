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
