import FilmEnrichment
import MiseCore
import Testing
@testable import AppCore

@MainActor
@Suite("LibraryController")
struct LibraryControllerTests {
    @Test("happy path publishes history, reaches done, and fills progress")
    func happyPathPublishesHistory() async throws {
        let bare = Fixtures.bareFilm()
        let fetcher = MockFetcher(diary: [Fixtures.diaryEntry(film: bare)])
        let store = InMemoryStore()
        let sut = LibraryController(
            store: store,
            makeFetcher: { fetcher },
            makeEnricher: { _ in FilmEnricher(provider: MockMetadataProvider()) }
        )

        await sut.load(handle: "tester", tmdbKey: "tmdb-key")

        #expect(sut.phase == .done)
        #expect(sut.progress == 1)
        #expect(sut.errorMessage == nil)
        let history = try #require(sut.history)
        #expect(history.member.username == "tester")
        // Enrichment ran: the diary film picked up its TMDB id.
        #expect(history.diary.first?.film.tmdbID == 42)
        // Result was persisted.
        #expect(await store.saved(for: "tester") != nil)
    }

    @Test("runs without enrichment when the TMDB key is empty")
    func runsWithoutEnrichmentWhenKeyEmpty() async throws {
        let bare = Fixtures.bareFilm()
        let fetcher = MockFetcher(diary: [Fixtures.diaryEntry(film: bare)])
        let store = InMemoryStore()
        let flag = CallFlag()
        let sut = LibraryController(
            store: store,
            makeFetcher: { fetcher },
            makeEnricher: { _ in
                flag.set()
                return FilmEnricher(provider: MockMetadataProvider())
            }
        )

        await sut.load(handle: "tester", tmdbKey: "")

        #expect(sut.phase == .done)
        #expect(flag.wasCalled == false)
        // Film passed through unchanged (no TMDB id).
        #expect(sut.history?.diary.first?.film.tmdbID == nil)
    }

    @Test("error path sets failed phase and error message")
    func errorPathSetsFailedState() async throws {
        let fetcher = MockFetcher(errorToThrow: TestError(message: "boom"))
        let store = InMemoryStore()
        let sut = LibraryController(
            store: store,
            makeFetcher: { fetcher },
            makeEnricher: { _ in nil }
        )

        await sut.load(handle: "tester", tmdbKey: nil)

        #expect(sut.phase == .failed("boom"))
        #expect(sut.errorMessage == "boom")
        #expect(sut.history == nil)
    }
}
