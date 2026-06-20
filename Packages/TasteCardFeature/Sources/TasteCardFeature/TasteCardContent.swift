import Foundation
import TasteProfile

/// A pure, view-agnostic projection of a `TasteProfile` into the small set of
/// display strings the card actually renders.
///
/// Keeping this separate from the SwiftUI view means the string mapping (the only
/// non-trivial logic on the card) is fully unit-testable without a renderer.
public struct TasteCardContent: Hashable, Sendable {

    /// The hero archetype, e.g. "Auteur Worshipper".
    public let archetype: String
    /// A short, evocative tagline derived from the archetype.
    public let tagline: String
    /// The card's masthead, always the product wordmark.
    public let masthead: String
    /// The defining genres as short display chips (label, falling back to name).
    public let genreChips: [String]
    /// Up to two framed hottest-take blurbs.
    public let takeBlurbs: [String]
    /// Headline stats as (value, label) pairs, capped for the card grid.
    public let stats: [Stat]
    /// One obsession line, e.g. "Returns to David Lynch · 5 films", or `nil`.
    public let obsessionLine: String?
    /// Footer call-to-action / attribution.
    public let footer: String

    public struct Stat: Hashable, Sendable, Identifiable {
        public var id: String { label }
        public let value: String
        public let label: String

        public init(value: String, label: String) {
            self.value = value
            self.label = label
        }
    }

    public init(
        archetype: String,
        tagline: String,
        masthead: String,
        genreChips: [String],
        takeBlurbs: [String],
        stats: [Stat],
        obsessionLine: String?,
        footer: String
    ) {
        self.archetype = archetype
        self.tagline = tagline
        self.masthead = masthead
        self.genreChips = genreChips
        self.takeBlurbs = takeBlurbs
        self.stats = stats
        self.obsessionLine = obsessionLine
        self.footer = footer
    }

    // MARK: - Tuning

    /// Max defining-genre chips shown on the card.
    static let maxGenreChips = 4
    /// Max hottest-take blurbs shown on the card.
    static let maxTakeBlurbs = 2
    /// Max headline stats shown on the card grid.
    static let maxStats = 4

    /// The product wordmark used as the card masthead.
    public static let masthead = "MISE"
    /// The card footer line.
    public static let footer = "My Taste DNA · made with Mise"

    // MARK: - Projection

    /// Builds the card content from a profile. Pure and deterministic.
    public static func make(from profile: TasteProfile) -> TasteCardContent {
        let chips = profile.definingGenres
            .prefix(maxGenreChips)
            .map { $0.label.isEmpty ? $0.name : $0.label }

        let blurbs = profile.hottestTakes
            .prefix(maxTakeBlurbs)
            .map(\.blurb)

        let stats = profile.headlineStats
            .prefix(maxStats)
            .map { Stat(value: $0.value, label: $0.label) }

        return TasteCardContent(
            archetype: profile.archetype,
            tagline: tagline(for: profile.archetype),
            masthead: masthead,
            genreChips: Array(chips),
            takeBlurbs: Array(blurbs),
            stats: Array(stats),
            obsessionLine: obsessionLine(for: profile),
            footer: footer
        )
    }

    /// A short evocative tagline for each known archetype, with a graceful
    /// fallback for the "<Genre> Specialist" family and anything unknown.
    public static func tagline(for archetype: String) -> String {
        switch archetype {
        case "Unwritten":
            return "A blank reel, waiting"
        case "Arthouse Contrarian":
            return "Against the grain, on purpose"
        case "Auteur Worshipper":
            return "Faithful to the vision"
        case "Decade Time-Traveler":
            return "Living in another era"
        case "Blockbuster Comfort-Watcher":
            return "Big screen, warm heart"
        case "Hot-Take Machine":
            return "Opinions, fully loaded"
        case "Eclectic Omnivore":
            return "Devours everything"
        default:
            if archetype.hasSuffix("Specialist") {
                return "Knows one world deeply"
            }
            return "A taste all your own"
        }
    }

    /// The single most prominent obsession, framed as a line. People (directors,
    /// cast) are favored over decades because they read better on a card.
    public static func obsessionLine(for profile: TasteProfile) -> String? {
        let ordered = profile.obsessions.sorted { lhs, rhs in
            if obsessionRank(lhs.kind) != obsessionRank(rhs.kind) {
                return obsessionRank(lhs.kind) < obsessionRank(rhs.kind)
            }
            if lhs.count != rhs.count { return lhs.count > rhs.count }
            return lhs.name < rhs.name
        }
        guard let top = ordered.first else { return nil }
        switch top.kind {
        case .director:
            return "Keeps returning to \(top.name) · \(top.label)"
        case .castMember:
            return "Can't quit \(top.name) · \(top.label)"
        case .decade:
            return "Lives in the \(top.name) · \(top.label)"
        }
    }

    private static func obsessionRank(_ kind: ObsessionKind) -> Int {
        switch kind {
        case .director:   return 0
        case .castMember: return 1
        case .decade:     return 2
        }
    }
}
