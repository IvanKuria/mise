import Testing
import MiseCore
import RecommenderEngine
@testable import CompareFeature

@Suite("CompareViewModel presentation logic")
struct CompareViewModelTests {

    // MARK: - Affinity mapping

    @Test("Pearson +1 maps to 100% affinity")
    func affinityPerfect() {
        #expect(CompareViewModel.affinityPercent(forSimilarity: 1.0) == 100)
    }

    @Test("Pearson 0 maps to 50% affinity")
    func affinityNeutral() {
        #expect(CompareViewModel.affinityPercent(forSimilarity: 0.0) == 50)
    }

    @Test("Pearson -1 maps to 0% affinity")
    func affinityOpposite() {
        #expect(CompareViewModel.affinityPercent(forSimilarity: -1.0) == 0)
    }

    @Test("Affinity clamps out-of-range similarity")
    func affinityClamps() {
        #expect(CompareViewModel.affinityPercent(forSimilarity: 5.0) == 100)
        #expect(CompareViewModel.affinityPercent(forSimilarity: -5.0) == 0)
    }

    @Test("Affinity rounds to nearest percent")
    func affinityRounds() {
        // 0.5 -> (1.5/2)*100 = 75
        #expect(CompareViewModel.affinityPercent(forSimilarity: 0.5) == 75)
    }

    @Test("Affinity captions track the score bands")
    func affinityCaptions() {
        #expect(CompareViewModel.affinityCaption(forSimilarity: 1.0) == "Cinematic soulmates")
        #expect(CompareViewModel.affinityCaption(forSimilarity: -1.0) == "Polar opposites")
        #expect(CompareViewModel.affinityCaption(forSimilarity: 0.0) == "A mixed bag")
    }

    // MARK: - Delta labels

    @Test("Delta label is signed from my point of view")
    func deltaSign() {
        #expect(CompareViewModel.deltaLabel(myStars: 5.0, theirStars: 2.0) == "+3.0")
        #expect(CompareViewModel.deltaLabel(myStars: 2.0, theirStars: 5.0) == "−3.0")
    }

    @Test("Equal ratings produce a zero delta")
    func deltaZero() {
        #expect(CompareViewModel.deltaLabel(myStars: 4.0, theirStars: 4.0) == "0.0")
    }

    @Test("Delta label shows one decimal for half-stars")
    func deltaHalf() {
        #expect(CompareViewModel.deltaLabel(myStars: 4.5, theirStars: 3.0) == "+1.5")
    }

    // MARK: - Overlap & disagreements (integration via compare())

    @Test("Real comparison reports overlap and shared count")
    func overlapFromCompare() {
        let model = CompareViewModel(
            me: CompareSampleData.me.member,
            other: CompareSampleData.other.member,
            comparison: compare(CompareSampleData.me, CompareSampleData.other)
        )
        #expect(model.hasOverlap)
        #expect(model.comparison.sharedFilmCount == 6)
        #expect(model.hasDisagreements)
    }

    @Test("topDisagreements excludes agreements and respects the limit")
    func topDisagreementsFilters() {
        let model = CompareViewModel(
            me: CompareSampleData.me.member,
            other: CompareSampleData.other.member,
            comparison: compare(CompareSampleData.me, CompareSampleData.other)
        )
        let top = model.topDisagreements(limit: 3)
        #expect(top.count <= 3)
        #expect(top.allSatisfy { $0.delta > 0 })
        // Sorted largest-gap first by the engine.
        if top.count >= 2 {
            #expect(top[0].delta >= top[1].delta)
        }
    }

    @Test("Per-disagreement delta label matches the rating gap")
    func perDisagreementDelta() {
        let model = CompareViewModel(
            me: CompareSampleData.me.member,
            other: CompareSampleData.other.member,
            comparison: compare(CompareSampleData.me, CompareSampleData.other)
        )
        let top = model.topDisagreements()
        let first = try! #require(top.first)
        let expected = CompareViewModel.deltaLabel(
            myStars: first.ratingA.stars,
            theirStars: first.ratingB.stars
        )
        #expect(model.deltaLabel(for: first) == expected)
    }

    // MARK: - No overlap

    @Test("No shared films reports no overlap and no disagreements")
    func noOverlap() {
        let model = CompareViewModel(
            me: CompareSampleData.meNoOverlap.member,
            other: CompareSampleData.otherNoOverlap.member,
            comparison: compare(CompareSampleData.meNoOverlap, CompareSampleData.otherNoOverlap)
        )
        #expect(!model.hasOverlap)
        #expect(!model.hasDisagreements)
        #expect(model.topDisagreements().isEmpty)
        #expect(model.sharedFilmCountText == "0")
    }

    // MARK: - Recommendation seeds

    @Test("Seed lists come from the comparison's loved-unseen films")
    func seedLists() {
        let comparison = compare(CompareSampleData.me, CompareSampleData.other)
        let model = CompareViewModel(
            me: CompareSampleData.me.member,
            other: CompareSampleData.other.member,
            comparison: comparison
        )
        #expect(model.forYou == comparison.bLovedAHasntSeen)
        #expect(model.forThem == comparison.aLovedBHasntSeen)
        #expect(!model.forYou.isEmpty)
        #expect(!model.forThem.isEmpty)
    }
}
