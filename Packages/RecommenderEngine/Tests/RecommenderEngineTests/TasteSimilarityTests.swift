import Testing
import MiseCore
@testable import RecommenderEngine

@Suite("tasteSimilarity")
struct TasteSimilarityTests {

    @Test("returns 0 when there are no shared rated films")
    func noSharedFilms() {
        let a = Fixtures.history("a", [("f1", 4.0), ("f2", 3.0), ("f3", 5.0)])
        let b = Fixtures.history("b", [("f4", 4.0), ("f5", 3.0), ("f6", 5.0)])
        #expect(tasteSimilarity(a, b) == 0)
    }

    @Test("returns 0 when shared rated films are fewer than the minimum")
    func belowMinimum() {
        let a = Fixtures.history("a", [("f1", 4.0), ("f2", 3.0)])
        let b = Fixtures.history("b", [("f1", 4.0), ("f2", 3.0)])
        // Only 2 shared, default minimum is 3.
        #expect(tasteSimilarity(a, b) == 0)
    }

    @Test("identical tastes yield similarity of (about) 1")
    func identicalTastes() {
        let ratings: [(String, Double?)] = [("f1", 5.0), ("f2", 1.0), ("f3", 3.5), ("f4", 4.0)]
        let a = Fixtures.history("a", ratings)
        let b = Fixtures.history("b", ratings)
        #expect(tasteSimilarity(a, b) > 0.99)
    }

    @Test("opposite tastes yield strongly negative similarity")
    func oppositeTastes() {
        let a = Fixtures.history("a", [("f1", 5.0), ("f2", 4.5), ("f3", 4.0), ("f4", 5.0)])
        let b = Fixtures.history("b", [("f1", 0.5), ("f2", 1.0), ("f3", 1.5), ("f4", 0.5)])
        #expect(tasteSimilarity(a, b) < -0.9)
    }

    @Test("ignores films logged without a rating in either diary")
    func ignoresUnratedEntries() {
        // f1..f3 rated in both; f4 rated by a but only logged (no rating) by b.
        let a = Fixtures.history("a", [("f1", 5.0), ("f2", 1.0), ("f3", 3.5), ("f4", 4.0)])
        let b = Fixtures.history("b", [("f1", 5.0), ("f2", 1.0), ("f3", 3.5), ("f4", nil)])
        // f4 is not a shared *rated* film, so this matches the 3-shared identical case.
        #expect(tasteSimilarity(a, b) > 0.99)
    }

    @Test("respects a custom minimum threshold")
    func customMinimum() {
        let a = Fixtures.history("a", [("f1", 4.0), ("f2", 3.0)])
        let b = Fixtures.history("b", [("f1", 4.0), ("f2", 3.0)])
        // 2 shared rated films, minimum lowered to 2 -> should compute, not 0.
        #expect(tasteSimilarity(a, b, minimumSharedFilms: 2) != 0)
    }

    @Test("is symmetric")
    func symmetric() {
        let a = Fixtures.history("a", [("f1", 5.0), ("f2", 2.0), ("f3", 3.5), ("f4", 4.0)])
        let b = Fixtures.history("b", [("f1", 4.0), ("f2", 3.0), ("f3", 4.0), ("f4", 2.5)])
        #expect(tasteSimilarity(a, b) == tasteSimilarity(b, a))
    }
}
