import Foundation
import Testing
import MiseCore
@testable import LetterboxdScrape

@Suite("ScrapingFetcher orchestration")
struct ScrapingFetcherTests {

    private func base(_ path: String) -> String {
        "https://letterboxd.com/\(path)"
    }

    @Test("member resolves profile to a MemberSummary")
    func member() async throws {
        let mock = MockFetcher(responses: [
            base("alice/"): try Fixture.html("profile"),
        ])
        let fetcher = ScrapingFetcher(fetcher: mock)
        let member = try await fetcher.member(username: "alice")
        #expect(member.id == "alice")
        #expect(member.username == "alice")
        #expect(member.avatarURL != nil)
    }

    @Test("logEntries walks all diary pages and stops at the reported total")
    func diaryPagination() async throws {
        // diary fixture reports 4 total pages; serve page 1, leave rest empty so
        // pagination terminates early on the empty page.
        let mock = MockFetcher(responses: [
            base("alice/diary/"): try Fixture.html("diary"),
        ])
        let fetcher = ScrapingFetcher(fetcher: mock)
        let entries = try await fetcher.logEntries(memberID: "alice", perPage: 50, cursor: nil)
        #expect(entries.count == 3) // only page 1 had rows; page 2 was empty -> stop
        // It requested page 1, then page 2 (empty) and stopped.
        let urls = await mock.requestedURLs()
        #expect(urls.contains(base("alice/diary/")))
        #expect(urls.contains(base("alice/diary/page/2/")))
        #expect(!urls.contains(base("alice/diary/page/3/")))
    }

    @Test("logEntries falls back to the diary HTML (honouring a page cursor) when RSS is empty")
    func diaryCursor() async throws {
        // No RSS response is registered, so the RSS primary source yields nothing
        // and logEntries falls back to the diary HTML at the requested cursor.
        let mock = MockFetcher(responses: [
            base("alice/diary/page/2/"): try Fixture.html("diary"),
        ])
        let fetcher = ScrapingFetcher(fetcher: mock)
        let entries = try await fetcher.logEntries(memberID: "alice", perPage: 50, cursor: "2")
        #expect(entries.count == 3)
        let urls = await mock.requestedURLs()
        // RSS is attempted first, then the diary fallback at page 2.
        #expect(urls.first == base("alice/rss/"))
        #expect(urls.contains(base("alice/diary/page/2/")))
    }

    @Test("films walks the grid across multiple pages")
    func filmsMultiPage() async throws {
        // films fixture reports 48 pages. Serve identical content on pages 1 & 2,
        // then empty on page 3 to terminate. Cap maxPages low to stay bounded.
        let mock = MockFetcher(responses: [
            base("alice/films/"): try Fixture.html("films"),
            base("alice/films/page/2/"): try Fixture.html("films"),
        ])
        let fetcher = ScrapingFetcher(fetcher: mock, maxPages: 10)
        let films = try await fetcher.films(memberID: "alice")
        #expect(films.count == 4) // 2 per page * 2 populated pages
    }

    @Test("watchlist parses items via the fetcher")
    func watchlist() async throws {
        let mock = MockFetcher(responses: [
            base("alice/watchlist/"): try Fixture.html("watchlist"),
        ])
        let fetcher = ScrapingFetcher(fetcher: mock)
        let items = try await fetcher.watchlist(memberID: "alice")
        #expect(items.count == 2)
    }

    @Test("lists parses the index without fetching list films by default")
    func listsNoEnrichment() async throws {
        let mock = MockFetcher(responses: [
            base("alice/lists/"): try Fixture.html("lists"),
        ])
        let fetcher = ScrapingFetcher(fetcher: mock)
        let lists = try await fetcher.lists(memberID: "alice")
        #expect(lists.count == 2)
        #expect(lists.allSatisfy { $0.films.isEmpty })
        // Only the lists index pages were requested (no /list/<id>/ fetches).
        let urls = await mock.requestedURLs()
        #expect(!urls.contains { $0.contains("/list/") })
    }

    @Test("statistics merges header counts with a derived ratings histogram")
    func statistics() async throws {
        let mock = MockFetcher(responses: [
            base("alice/"): try Fixture.html("profile"),
            base("alice/films/"): try Fixture.html("films"),
        ])
        let fetcher = ScrapingFetcher(fetcher: mock)
        let stats = try await fetcher.statistics(memberID: "alice")
        #expect(stats.watchedFilmCount == 3397) // from header
        #expect(stats.listCount == 73)
        // films fixture has one rated-6 film -> histogram[6] == 1.
        #expect(stats.ratingsHistogram[6] == 1)
    }

    @Test("a non-2xx HTTP status surfaces as ScrapeError.httpStatus")
    func httpError() async {
        let failing = StatusFetcher(status: 403)
        let fetcher = ScrapingFetcher(fetcher: failing)
        await #expect(throws: ScrapeError.self) {
            _ = try await fetcher.member(username: "blocked")
        }
    }
}

// MARK: - Test doubles

private extension MockFetcher {
    func requestedURLs() async -> [String] {
        // `requested` is mutated on the actor-free MockFetcher; read synchronously.
        requested.map(\.absoluteString)
    }
}

/// Always throws an HTTP status error, to exercise error propagation.
private struct StatusFetcher: HTMLFetching {
    let status: Int
    func html(for url: URL) async throws -> String {
        throw ScrapeError.httpStatus(status, url: url)
    }
}
