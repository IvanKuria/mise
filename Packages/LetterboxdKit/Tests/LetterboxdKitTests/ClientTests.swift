import Foundation
import Testing
import MiseCore
@testable import LetterboxdKit

@Suite("LetterboxdClient endpoints (mock transport)")
struct ClientTests {

    private func makeClient(
        _ responses: [MockTransport.Response],
        maxRetries: Int = 3
    ) -> (LetterboxdClient, MockTransport) {
        let transport = MockTransport(responses: responses)
        let config = LetterboxdConfiguration(apiKey: "KEY", apiSecret: "shhh")
        let creds = FixedCredentialsProvider(fixedNonce: "N", fixedTimestamp: 100)
        let client = LetterboxdClient(
            configuration: config,
            transport: transport,
            credentials: creds,
            maxRetries: maxRetries
        )
        return (client, transport)
    }

    // First call always triggers a token fetch (response[0]); endpoint = response[1].

    @Test("statistics fetches a token then the statistics endpoint")
    func statistics() async throws {
        let (client, transport) = makeClient([
            .init(data: Fixtures.token),
            .init(data: Fixtures.statistics),
        ])
        let stats = try await client.statistics(memberID: "MEM1")
        #expect(stats.watchedFilmCount == 2500)
        #expect(transport.callCount == 2)

        // Token call is POST to auth/token; second call carries the bearer token.
        #expect(transport.recordedRequests[0].httpMethod == "POST")
        #expect(transport.recordedRequests[0].url!.path.contains("auth/token"))
        #expect(transport.recordedRequests[1].value(forHTTPHeaderField: "Authorization") == "Bearer abc123token")
        #expect(transport.recordedRequests[1].url!.path.contains("member/MEM1/statistics"))
    }

    @Test("token is cached across calls")
    func tokenCaching() async throws {
        let (client, transport) = makeClient([
            .init(data: Fixtures.token),
            .init(data: Fixtures.statistics),
            .init(data: Fixtures.watchlist),
        ])
        _ = try await client.statistics(memberID: "MEM1")
        _ = try await client.watchlist(memberID: "MEM1")
        // Only ONE token fetch -> 3 total calls (1 token + 2 endpoints).
        #expect(transport.callCount == 3)
    }

    @Test("member resolves a username via search")
    func member() async throws {
        let (client, _) = makeClient([
            .init(data: Fixtures.token),
            .init(data: Fixtures.memberSearch),
        ])
        let m = try await client.member(username: "dave")
        #expect(m.id == "MEM123")
        #expect(m.username == "dave")
    }

    @Test("member throws memberNotFound when search is empty")
    func memberNotFound() async throws {
        let empty = Data(#"{"items":[]}"#.utf8)
        let (client, _) = makeClient([
            .init(data: Fixtures.token),
            .init(data: empty),
        ])
        await #expect(throws: LetterboxdError.memberNotFound("ghost")) {
            try await client.member(username: "ghost")
        }
    }

    @Test("logEntries maps diary entries")
    func logEntries() async throws {
        let (client, transport) = makeClient([
            .init(data: Fixtures.token),
            .init(data: Fixtures.logEntries),
        ])
        let entries = try await client.logEntries(memberID: "MEM1", perPage: 10)
        #expect(entries.count == 2)
        #expect(entries.first?.rating == Rating(stars: 4.5))
        let query = transport.recordedRequests[1].url!.query ?? ""
        #expect(query.contains("member=MEM1"))
        #expect(query.contains("perPage=10"))
    }

    @Test("watchlist maps items")
    func watchlist() async throws {
        let (client, _) = makeClient([
            .init(data: Fixtures.token),
            .init(data: Fixtures.watchlist),
        ])
        let items = try await client.watchlist(memberID: "MEM1")
        #expect(items.count == 2)
    }

    @Test("lists maps film lists")
    func lists() async throws {
        let (client, _) = makeClient([
            .init(data: Fixtures.token),
            .init(data: Fixtures.lists),
        ])
        let lists = try await client.lists(memberID: "MEM1")
        #expect(lists.first?.films.count == 2)
    }

    @Test("film fetches a single film")
    func film() async throws {
        let (client, _) = makeClient([
            .init(data: Fixtures.token),
            .init(data: Fixtures.film),
        ])
        let f = try await client.film(id: "2bbs")
        #expect(f.tmdbID == 496243)
    }

    @Test("search returns only film items")
    func search() async throws {
        let (client, _) = makeClient([
            .init(data: Fixtures.token),
            .init(data: Fixtures.filmSearch),
        ])
        let results = try await client.search(query: "parasite")
        #expect(results.count == 1)
        #expect(results.first?.name == "Parasite")
    }

    @Test("retries on 429 then succeeds")
    func retryOn429() async throws {
        let (client, transport) = makeClient([
            .init(data: Fixtures.token),
            .init(status: 429, data: Data()),
            .init(status: 200, data: Fixtures.statistics),
        ], maxRetries: 3)
        let stats = try await client.statistics(memberID: "MEM1")
        #expect(stats.watchedFilmCount == 2500)
        // token + 429 + retry success = 3 calls.
        #expect(transport.callCount == 3)
    }

    @Test("retries on 503 then succeeds")
    func retryOn503() async throws {
        let (client, _) = makeClient([
            .init(data: Fixtures.token),
            .init(status: 503, data: Data()),
            .init(status: 503, data: Data()),
            .init(status: 200, data: Fixtures.watchlist),
        ], maxRetries: 3)
        let items = try await client.watchlist(memberID: "MEM1")
        #expect(items.count == 2)
    }

    @Test("non-retryable 404 throws httpStatus")
    func notFound() async throws {
        let (client, _) = makeClient([
            .init(data: Fixtures.token),
            .init(status: 404, data: Data("nope".utf8)),
        ])
        await #expect(throws: LetterboxdError.httpStatus(code: 404, body: Data("nope".utf8))) {
            try await client.film(id: "missing")
        }
    }

    @Test("persistent 5xx exhausts retries")
    func retriesExhausted() async throws {
        let (client, _) = makeClient([
            .init(data: Fixtures.token),
            .init(status: 500, data: Data()),
        ], maxRetries: 1)
        await #expect(throws: LetterboxdError.retriesExhausted(lastStatus: 500)) {
            try await client.film(id: "x")
        }
    }
}
