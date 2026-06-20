import FilmEnrichment
import MiseCore
import Testing
@testable import AppCore

@Suite("EnrichingFetcher")
struct EnrichingFetcherTests {
    @Test("enriches diary films when an enricher is present")
    func enrichesDiaryWhenEnricherPresent() async throws {
        let bare = Fixtures.bareFilm()
        let base = MockFetcher(diary: [Fixtures.diaryEntry(film: bare)])
        let enricher = FilmEnricher(provider: MockMetadataProvider())
        let sut = EnrichingFetcher(base: base, enricher: enricher)

        let entries = try await sut.logEntries(memberID: "m1", perPage: 50, cursor: nil)

        #expect(entries.count == 1)
        let film = try #require(entries.first).film
        #expect(film.tmdbID == 42)
        #expect(film.runtimeMinutes == 132)
        #expect(film.genres.map(\.name) == ["Drama", "Thriller"])
        #expect(film.posterURL?.absoluteString == "https://image.tmdb.org/t/p/w500/poster.jpg")
        // Non-film fields are preserved.
        #expect(entries.first?.id == "d1")
    }

    @Test("enriches watchlist and list films when an enricher is present")
    func enrichesWatchlistAndLists() async throws {
        let bare = Fixtures.bareFilm(id: "f2", name: "Burning")
        let base = MockFetcher(
            watchlistItems: [WatchlistItem(film: bare)],
            filmLists: [FilmList(id: "l1", name: "Faves", films: [bare])]
        )
        let enricher = FilmEnricher(provider: MockMetadataProvider())
        let sut = EnrichingFetcher(base: base, enricher: enricher)

        let watchlist = try await sut.watchlist(memberID: "m1")
        let lists = try await sut.lists(memberID: "m1")

        #expect(watchlist.first?.film.tmdbID == 42)
        #expect(lists.first?.films.first?.tmdbID == 42)
        #expect(lists.first?.name == "Faves")
    }

    @Test("passes films through unchanged when the enricher is nil")
    func passesThroughWhenEnricherNil() async throws {
        let bare = Fixtures.bareFilm()
        let base = MockFetcher(
            diary: [Fixtures.diaryEntry(film: bare)],
            watchlistItems: [WatchlistItem(film: bare)],
            filmLists: [FilmList(id: "l1", name: "Faves", films: [bare])]
        )
        let sut = EnrichingFetcher(base: base, enricher: nil)

        let entries = try await sut.logEntries(memberID: "m1", perPage: 50, cursor: nil)
        let watchlist = try await sut.watchlist(memberID: "m1")
        let lists = try await sut.lists(memberID: "m1")

        #expect(entries.first?.film == bare)
        #expect(entries.first?.film.tmdbID == nil)
        #expect(watchlist.first?.film == bare)
        #expect(lists.first?.films.first == bare)
    }

    @Test("member and statistics always pass through")
    func memberAndStatisticsPassThrough() async throws {
        let stats = MemberStatistics(watchedFilmCount: 7)
        let base = MockFetcher(
            member: MemberSummary(id: "m1", username: "tester", displayName: "T"),
            statistics: stats
        )
        let enricher = FilmEnricher(provider: MockMetadataProvider())
        let sut = EnrichingFetcher(base: base, enricher: enricher)

        let member = try await sut.member(username: "tester")
        let returnedStats = try await sut.statistics(memberID: "m1")

        #expect(member.username == "tester")
        #expect(returnedStats.watchedFilmCount == 7)
    }
}
