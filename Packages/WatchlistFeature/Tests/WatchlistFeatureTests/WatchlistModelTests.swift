import Testing
import MiseCore
import WatchlistPlanner
@testable import WatchlistFeature

@MainActor
private func makeModel(
    ranking: Ranking = .random(seed: 0)
) -> WatchlistModel {
    WatchlistModel(
        watchlist: WatchlistPreviewData.watchlist,
        availability: WatchlistPreviewData.availability,
        ranking: ranking,
        seed: 1234
    )
}

@Suite("WatchlistModel")
struct WatchlistModelTests {

    @MainActor
    @Test("No criteria includes the whole watchlist")
    func noCriteria() {
        let model = makeModel()
        #expect(model.candidates.count == WatchlistPreviewData.watchlist.count)
        #expect(model.pick != nil)
        #expect(model.hasActiveCriteria == false)
    }

    @MainActor
    @Test("Runtime cap narrows candidates and excludes the long film")
    func runtimeCap() {
        let model = makeModel()
        model.maxRuntimeMinutes = 105

        #expect(model.hasActiveCriteria)
        // Stalker (162), Heat (170), Burning (148), Portrait (122) excluded.
        #expect(!model.candidates.contains { $0.id == "w-2" })
        #expect(!model.candidates.contains { $0.id == "w-3" })
        #expect(!model.candidates.contains { $0.id == "w-7" })
        #expect(model.candidates.allSatisfy { ($0.film.runtimeMinutes ?? .max) <= 105 })
        // The pick must itself satisfy the cap.
        #expect((model.pick?.film.runtimeMinutes ?? .max) <= 105)
    }

    @MainActor
    @Test("Genre selection filters to match-any of the chosen genres")
    func genreFilter() {
        let model = makeModel()
        model.toggleGenre("Horror")

        #expect(model.candidates.count == 1)
        #expect(model.pick?.id == "w-9") // The Lighthouse
    }

    @MainActor
    @Test("Service selection filters to films available on those services")
    func serviceFilter() {
        let model = makeModel()
        model.toggleService("Netflix")

        let ids = Set(model.candidates.map(\.id))
        #expect(ids == ["w-6", "w-10"])
    }

    @MainActor
    @Test("Minimum average excludes lower-rated films")
    func minAverage() {
        let model = makeModel()
        model.minAverage = 4.2

        #expect(model.candidates.allSatisfy {
            ($0.film.letterboxdAverageRating ?? 0) >= 4.2
        })
        #expect(!model.candidates.contains { $0.id == "w-9" }) // 3.8
    }

    @MainActor
    @Test("Criteria compose with AND across dimensions")
    func composedCriteria() {
        let model = makeModel()
        model.maxRuntimeMinutes = 120
        model.toggleGenre("Romance")
        model.minAverage = 4.0

        for item in model.candidates {
            #expect((item.film.runtimeMinutes ?? .max) <= 120)
            #expect(item.film.genres.contains { $0.name == "Romance" })
            #expect((item.film.letterboxdAverageRating ?? 0) >= 4.0)
        }
        #expect(!model.candidates.isEmpty)
    }

    @MainActor
    @Test("Impossible criteria yield no candidates and no pick")
    func emptyResult() {
        let model = makeModel()
        model.toggleGenre("Horror")
        model.maxRuntimeMinutes = 90 // The Lighthouse is 109

        #expect(model.candidates.isEmpty)
        #expect(model.pick == nil)
    }

    @MainActor
    @Test("Clearing criteria restores the full watchlist")
    func clearCriteria() {
        let model = makeModel()
        model.toggleGenre("Horror")
        model.maxRuntimeMinutes = 90
        #expect(model.candidates.isEmpty)

        model.clearCriteria()
        #expect(model.hasActiveCriteria == false)
        #expect(model.candidates.count == WatchlistPreviewData.watchlist.count)
        #expect(model.pick != nil)
    }

    @MainActor
    @Test("shortestFirst ranking picks the shortest candidate")
    func shortestFirstPick() {
        let model = makeModel(ranking: .shortestFirst)
        // In the Mood for Love (98) is the shortest in the set.
        #expect(model.pick?.id == "w-1")
        // And the grid is ordered shortest-first.
        #expect(model.candidates.first?.id == "w-1")
    }

    @MainActor
    @Test("highestRated ranking picks the top-rated candidate")
    func highestRatedPick() {
        let model = makeModel(ranking: .highestRated)
        // In the Mood for Love has 4.4, the highest.
        #expect(model.pick?.id == "w-1")
        #expect(model.candidates.first?.id == "w-1")
    }

    @MainActor
    @Test("Reroll eventually changes the pick under random ranking")
    func rerollVaries() {
        let model = makeModel(ranking: .random(seed: 0))
        let first = model.pick?.id
        #expect(first != nil)

        var changed = false
        for _ in 0..<20 {
            model.reroll()
            if model.pick?.id != first {
                changed = true
                break
            }
        }
        #expect(changed, "Reroll should surface a different pick within a few tries")
    }

    @MainActor
    @Test("Reroll keeps the pick within the active candidate set")
    func rerollRespectsCriteria() {
        let model = makeModel(ranking: .random(seed: 0))
        model.toggleGenre("Romance")
        let allowed = Set(model.candidates.map(\.id))

        for _ in 0..<10 {
            model.reroll()
            #expect(model.pick.map { allowed.contains($0.id) } == true)
        }
    }

    @MainActor
    @Test("Available facets are derived from the watchlist")
    func facets() {
        let model = makeModel()
        #expect(model.availableGenres.contains("Romance"))
        #expect(model.availableGenres.contains("Horror"))
        #expect(model.availableServices.contains("Netflix"))
        #expect(model.availableServices.contains("Criterion"))
        // Sorted.
        #expect(model.availableGenres == model.availableGenres.sorted())
    }
}

@Suite("PickRationale")
struct PickRationaleTests {

    @Test("Reason mentions matched genre and rating when those criteria are set")
    func reasonMentionsCriteria() {
        let item = WatchlistPreviewData.watchlist.first { $0.id == "w-1" }!
        let criteria = TonightCriteria(
            genres: ["Romance"],
            minLetterboxdAverage: 4.0
        )
        let reason = PickRationale.reason(
            for: item,
            criteria: criteria,
            availability: WatchlistPreviewData.availability,
            ranking: .random(seed: 0)
        )
        #expect(reason.lowercased().contains("romance"))
        #expect(reason.contains("4.4"))
    }

    @Test("Reason falls back to a friendly default with no criteria")
    func reasonFallback() {
        let item = WatchlistPreviewData.watchlist.first!
        let reason = PickRationale.reason(
            for: item,
            criteria: TonightCriteria(),
            availability: .init(),
            ranking: .random(seed: 0)
        )
        #expect(!reason.isEmpty)
    }

    @Test("Meta line includes year, runtime, and rating")
    func metaLine() {
        let film = WatchlistPreviewData.films.first!
        let line = PickRationale.metaLine(for: film)
        #expect(line.contains("2000"))
        #expect(line.contains("98 min"))
        #expect(line.contains("4.4"))
    }
}
