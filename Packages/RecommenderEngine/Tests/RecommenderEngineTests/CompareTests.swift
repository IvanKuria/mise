import Testing
import MiseCore
@testable import RecommenderEngine

@Suite("compare")
struct CompareTests {

    @Test("counts only films both members rated")
    func sharedFilmCount() {
        // f1..f3 rated by both; f4 only by a; f5 logged-no-rating by b.
        let a = Fixtures.history("a", [("f1", 4.0), ("f2", 3.0), ("f3", 5.0), ("f4", 2.0)])
        let b = Fixtures.history("b", [("f1", 4.0), ("f2", 3.0), ("f3", 5.0), ("f5", nil)])
        let result = compare(a, b)
        #expect(result.sharedFilmCount == 3)
    }

    @Test("similarity matches tasteSimilarity")
    func similarityMatches() {
        let a = Fixtures.history("a", [("f1", 5.0), ("f2", 2.0), ("f3", 3.5), ("f4", 4.0)])
        let b = Fixtures.history("b", [("f1", 4.0), ("f2", 3.0), ("f3", 4.0), ("f4", 2.5)])
        let result = compare(a, b)
        #expect(result.similarity == tasteSimilarity(a, b))
    }

    @Test("disagreements are sorted by largest rating gap first")
    func disagreementsSorted() {
        let a = Fixtures.history("a", [("f1", 5.0), ("f2", 5.0), ("f3", 3.0)])
        let b = Fixtures.history("b", [("f1", 4.5), ("f2", 1.0), ("f3", 2.0)])
        // gaps: f1 0.5, f2 4.0, f3 1.0  -> order f2, f3, f1
        let result = compare(a, b)
        let ids = result.biggestDisagreements.map { $0.film.id }
        #expect(ids == ["f2", "f3", "f1"])
        #expect(result.biggestDisagreements.first?.delta == 4.0)
    }

    @Test("disagreement carries both ratings in the right slots")
    func disagreementRatings() {
        let a = Fixtures.history("a", [("f1", 5.0), ("f2", 1.0), ("f3", 3.0)])
        let b = Fixtures.history("b", [("f1", 1.0), ("f2", 2.0), ("f3", 3.0)])
        let result = compare(a, b)
        let top = result.biggestDisagreements.first!
        #expect(top.film.id == "f1")
        #expect(top.ratingA.stars == 5.0)
        #expect(top.ratingB.stars == 1.0)
    }

    @Test("seeds: films one loved (>= 4.5) the other has never logged")
    func lovedUnseenSeeds() {
        // a loved f10 (5.0) and f11 (4.5); b loved f20 (4.5).
        // b has logged f10 (so not a seed), but never f11 -> f11 is a seed for b.
        // a has never logged f20 -> f20 is a seed for a.
        let a = Fixtures.history("a", [("f1", 3.0), ("f10", 5.0), ("f11", 4.5)])
        let b = Fixtures.history("b", [("f1", 3.0), ("f10", 2.0), ("f20", 4.5)])
        let result = compare(a, b)
        #expect(result.aLovedBHasntSeen.map { $0.id } == ["f11"])
        #expect(result.bLovedAHasntSeen.map { $0.id } == ["f20"])
    }

    @Test("a film logged without a rating does not count as 'seen' for seeds... but logged counts as a diary entry")
    func seedsUseDiaryPresence() {
        // a loved f10. b logged f10 without a rating. b HAS a diary entry for f10,
        // so f10 is NOT a seed for b (the spec: other has no diary entry for it).
        let a = Fixtures.history("a", [("f10", 5.0), ("f1", 3.0), ("f2", 3.0), ("f3", 3.0)])
        let b = Fixtures.history("b", [("f10", nil), ("f1", 3.0), ("f2", 3.0), ("f3", 3.0)])
        let result = compare(a, b)
        #expect(result.aLovedBHasntSeen.isEmpty)
    }

    @Test("empty histories give an empty, zero comparison")
    func emptyHistories() {
        let a = WatchHistory(member: Fixtures.member("a"))
        let b = WatchHistory(member: Fixtures.member("b"))
        let result = compare(a, b)
        #expect(result.sharedFilmCount == 0)
        #expect(result.similarity == 0)
        #expect(result.biggestDisagreements.isEmpty)
        #expect(result.aLovedBHasntSeen.isEmpty)
        #expect(result.bLovedAHasntSeen.isEmpty)
    }

    @Test("seeds are deterministically ordered by film id")
    func seedsDeterministic() {
        let a = Fixtures.history("a", [("f30", 5.0), ("f10", 5.0), ("f20", 4.5)])
        let b = WatchHistory(member: Fixtures.member("b"))
        let result = compare(a, b)
        #expect(result.aLovedBHasntSeen.map { $0.id } == ["f10", "f20", "f30"])
    }
}
