import Testing
import MiseCore
@testable import RecommenderEngine

@Suite("recommendations")
struct RecommendationTests {

    /// A "twin" of `base` (same shared ratings -> high similarity) who also
    /// rates the extra films given.
    static func similarOther(
        id: String,
        sharing base: [(String, Double?)],
        plus extras: [(String, Double?)]
    ) -> WatchHistory {
        Fixtures.history(id, base + extras)
    }

    // A baseline target with a stable taste fingerprint.
    static let baseRatings: [(String, Double?)] = [
        ("anchor1", 5.0), ("anchor2", 1.0), ("anchor3", 3.5), ("anchor4", 4.0),
    ]

    @Test("empty others yields no recommendations")
    func emptyOthers() {
        let target = Fixtures.history("t", Self.baseRatings)
        #expect(recommendations(for: target, from: [], limit: 10).isEmpty)
    }

    @Test("recommends a highly-rated film the target hasn't logged")
    func basicRecommendation() {
        let target = Fixtures.history("t", Self.baseRatings)
        let other = Self.similarOther(id: "o", sharing: Self.baseRatings, plus: [("new1", 5.0)])
        let recs = recommendations(for: target, from: [other], limit: 10)
        #expect(recs.map { $0.film.id } == ["new1"])
        #expect(recs.first?.supportingMemberCount == 1)
        #expect(recs.first!.score > 0)
    }

    @Test("does not recommend films already in the target's diary")
    func excludesAlreadySeen() {
        // target already logged anchor1; even though other loves it, skip it.
        let target = Fixtures.history("t", Self.baseRatings)
        let other = Self.similarOther(id: "o", sharing: Self.baseRatings, plus: [])
        // other re-rates anchor1 at 5.0 (already in base) and adds nothing new.
        let recs = recommendations(for: target, from: [other], limit: 10)
        #expect(recs.isEmpty)
    }

    @Test("ignores films rated below 4.0 by others")
    func ignoresLowRated() {
        let target = Fixtures.history("t", Self.baseRatings)
        let other = Self.similarOther(id: "o", sharing: Self.baseRatings, plus: [("meh", 3.5)])
        let recs = recommendations(for: target, from: [other], limit: 10)
        #expect(recs.isEmpty)
    }

    @Test("ignores others whose similarity is <= 0")
    func ignoresDissimilarMembers() {
        let target = Fixtures.history("t", Self.baseRatings)
        // An "opposite" member: negatively correlated with target.
        let opposite = Fixtures.history("opp", [
            ("anchor1", 0.5), ("anchor2", 5.0), ("anchor3", 1.5), ("anchor4", 1.0),
            ("new1", 5.0),
        ])
        let recs = recommendations(for: target, from: [opposite], limit: 10)
        #expect(recs.isEmpty)
    }

    @Test("aggregates score and member count across supporting members")
    func aggregatesAcrossMembers() {
        let target = Fixtures.history("t", Self.baseRatings)
        let o1 = Self.similarOther(id: "o1", sharing: Self.baseRatings, plus: [("new1", 5.0)])
        let o2 = Self.similarOther(id: "o2", sharing: Self.baseRatings, plus: [("new1", 4.5)])
        let recs = recommendations(for: target, from: [o1, o2], limit: 10)
        #expect(recs.count == 1)
        #expect(recs.first?.film.id == "new1")
        #expect(recs.first?.supportingMemberCount == 2)
    }

    @Test("ranks by score descending and respects the limit")
    func ranksAndLimits() {
        let target = Fixtures.history("t", Self.baseRatings)
        // new1 supported by two similar members; new2 by one -> new1 ranks first.
        let o1 = Self.similarOther(id: "o1", sharing: Self.baseRatings, plus: [("new1", 5.0), ("new2", 5.0)])
        let o2 = Self.similarOther(id: "o2", sharing: Self.baseRatings, plus: [("new1", 5.0)])
        let recsAll = recommendations(for: target, from: [o1, o2], limit: 10)
        #expect(recsAll.map { $0.film.id } == ["new1", "new2"])
        #expect(recsAll[0].score >= recsAll[1].score)

        let recsLimited = recommendations(for: target, from: [o1, o2], limit: 1)
        #expect(recsLimited.map { $0.film.id } == ["new1"])
    }

    @Test("limit of zero returns nothing")
    func zeroLimit() {
        let target = Fixtures.history("t", Self.baseRatings)
        let other = Self.similarOther(id: "o", sharing: Self.baseRatings, plus: [("new1", 5.0)])
        #expect(recommendations(for: target, from: [other], limit: 0).isEmpty)
    }

    @Test("ties broken deterministically by film id")
    func tiesDeterministic() {
        let target = Fixtures.history("t", Self.baseRatings)
        // One member loves two new films equally -> equal scores, tie on id.
        let other = Self.similarOther(id: "o", sharing: Self.baseRatings, plus: [("zfilm", 5.0), ("afilm", 5.0)])
        let recs = recommendations(for: target, from: [other], limit: 10)
        #expect(recs.map { $0.film.id } == ["afilm", "zfilm"])
    }
}
