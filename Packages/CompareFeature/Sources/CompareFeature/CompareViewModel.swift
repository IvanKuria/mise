import Foundation
import MiseCore
import RecommenderEngine

/// Pure, view-agnostic presentation logic for the compare screen. Derived
/// entirely from a `MemberComparison` plus the two members so the SwiftUI layer
/// stays thin and the formatting is unit-testable.
public struct CompareViewModel: Equatable, Sendable {
    /// The first member (the `me` / `a` side of the comparison).
    public let me: MemberSummary
    /// The second member (the `other` / `b` side of the comparison).
    public let other: MemberSummary
    /// The underlying engine result.
    public let comparison: MemberComparison

    public init(me: MemberSummary, other: MemberSummary, comparison: MemberComparison) {
        self.me = me
        self.other = other
        self.comparison = comparison
    }

    /// True when the two members share no rated films — nothing to compare.
    public var hasOverlap: Bool {
        comparison.sharedFilmCount > 0
    }

    /// The number of shared rated films, formatted for display.
    public var sharedFilmCountText: String {
        String(comparison.sharedFilmCount)
    }

    // MARK: - Taste similarity

    /// Taste similarity (-1...1) mapped to a 0...100 affinity percentage, where
    /// -1 → 0%, 0 → 50%, +1 → 100%. Pearson can be negative; an affinity readout
    /// reads more naturally to a person than a signed correlation.
    public static func affinityPercent(forSimilarity similarity: Double) -> Int {
        let clamped = min(1, max(-1, similarity))
        return Int((((clamped + 1) / 2) * 100).rounded())
    }

    /// The big affinity readout, e.g. "87%".
    public var affinityPercentText: String {
        "\(Self.affinityPercent(forSimilarity: comparison.similarity))%"
    }

    /// A short qualitative caption for the affinity score.
    public static func affinityCaption(forSimilarity similarity: Double) -> String {
        switch affinityPercent(forSimilarity: similarity) {
        case 85...100: return "Cinematic soulmates"
        case 70..<85:  return "Kindred tastes"
        case 55..<70:  return "Mostly aligned"
        case 45..<55:  return "A mixed bag"
        case 30..<45:  return "Often at odds"
        default:       return "Polar opposites"
        }
    }

    /// Qualitative caption for the current comparison.
    public var affinityCaption: String {
        Self.affinityCaption(forSimilarity: comparison.similarity)
    }

    // MARK: - Disagreements

    /// The biggest disagreements, capped to a sensible display count, excluding
    /// films the two actually agreed on (zero delta).
    public func topDisagreements(limit: Int = 6) -> [RatingDisagreement] {
        Array(comparison.biggestDisagreements.filter { $0.delta > 0 }.prefix(limit))
    }

    /// True when there is at least one genuine disagreement to show.
    public var hasDisagreements: Bool {
        comparison.biggestDisagreements.contains { $0.delta > 0 }
    }

    /// A signed delta label for a disagreement from `me`'s point of view, e.g.
    /// "+1.5" when I rated it higher, "−2.0" when they did.
    public static func deltaLabel(myStars: Double, theirStars: Double) -> String {
        let diff = myStars - theirStars
        let magnitude = String(format: "%.1f", abs(diff))
        if diff > 0 { return "+\(magnitude)" }
        if diff < 0 { return "−\(magnitude)" }
        return "0.0"
    }

    /// The delta label for a specific disagreement.
    public func deltaLabel(for disagreement: RatingDisagreement) -> String {
        Self.deltaLabel(
            myStars: disagreement.ratingA.stars,
            theirStars: disagreement.ratingB.stars
        )
    }

    // MARK: - Recommendation seeds

    /// Films `other` loved that `me` hasn't seen — seeds to recommend to `me`.
    public var forYou: [Film] { comparison.bLovedAHasntSeen }

    /// Films `me` loved that `other` hasn't seen — seeds to recommend to `other`.
    public var forThem: [Film] { comparison.aLovedBHasntSeen }
}
