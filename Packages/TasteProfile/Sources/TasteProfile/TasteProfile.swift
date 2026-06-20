import Foundation

/// A ranked genre the member watches notably more than their own baseline.
///
/// `lift` is how over-represented the genre is relative to an even split across
/// the genres the member actually watches: `share / (1 / distinctGenres)`, i.e.
/// `share * distinctGenres`. A lift of 1.0 means perfectly average; 2.0 means the
/// genre is watched twice as often as an even spread would predict.
public struct DefiningGenre: Hashable, Sendable, Identifiable {
    public var id: String { name }
    public let name: String
    /// Number of logged entries in this genre.
    public let count: Int
    /// Fraction of all genre-tagged entries that fall in this genre (0...1).
    public let share: Double
    /// How over-indexed this genre is vs. an even split (see type docs).
    public let lift: Double
    /// A short human label, e.g. "Horror" or "Sci-Fi devotee".
    public let label: String

    public init(name: String, count: Int, share: Double, lift: Double, label: String) {
        self.name = name
        self.count = count
        self.share = share
        self.lift = lift
        self.label = label
    }
}

/// The direction of a contrarian take relative to the crowd.
public enum TakeDirection: String, Hashable, Sendable, Codable {
    /// Member rated it well above the community average.
    case lovedItCrowdDidnt
    /// Member rated it well below the community average.
    case dislikedItCrowdLoved
}

/// A single contrarian take, framed for the share card.
public struct HottestTake: Hashable, Sendable, Identifiable {
    public var id: String { filmID }
    public let filmID: String
    public let filmName: String
    public let memberStars: Double
    public let communityStars: Double
    /// memberStars - communityStars.
    public let delta: Double
    public let direction: TakeDirection
    /// A framed sentence, e.g. "You loved Mandy — the crowd didn't."
    public let blurb: String

    public init(
        filmID: String,
        filmName: String,
        memberStars: Double,
        communityStars: Double,
        delta: Double,
        direction: TakeDirection,
        blurb: String
    ) {
        self.filmID = filmID
        self.filmName = filmName
        self.memberStars = memberStars
        self.communityStars = communityStars
        self.delta = delta
        self.direction = direction
        self.blurb = blurb
    }
}

/// The kind of thing the member over-indexes on.
public enum ObsessionKind: String, Hashable, Sendable, Codable {
    case director
    case castMember
    case decade
}

/// A person or decade the member returns to far more than average.
public struct Obsession: Hashable, Sendable, Identifiable {
    public var id: String { "\(kind.rawValue):\(key)" }
    public let kind: ObsessionKind
    /// Stable key: person id for people, the decade's start year as a string for decades.
    public let key: String
    /// Display name, e.g. "David Lynch" or "1980s".
    public let name: String
    public let count: Int
    /// A short label, e.g. "5 films".
    public let label: String

    public init(kind: ObsessionKind, key: String, name: String, count: Int, label: String) {
        self.kind = kind
        self.key = key
        self.name = name
        self.count = count
        self.label = label
    }
}

/// The kind of gap a blind spot represents.
public enum BlindSpotKind: String, Hashable, Sendable, Codable {
    case genre
    case decade
}

/// A notable gap: something a typical cinephile distribution covers that this
/// member has near-zero presence in.
public struct BlindSpot: Hashable, Sendable, Identifiable {
    public var id: String { "\(kind.rawValue):\(key)" }
    public let kind: BlindSpotKind
    public let key: String
    public let name: String
    public let count: Int
    /// A short label, e.g. "Never logged a Western".
    public let label: String

    public init(kind: BlindSpotKind, key: String, name: String, count: Int, label: String) {
        self.kind = kind
        self.key = key
        self.name = name
        self.count = count
        self.label = label
    }
}

/// A single punchy headline number for the card.
public struct HeadlineStat: Hashable, Sendable, Identifiable {
    public var id: String { key }
    /// Stable key, e.g. "filmsLogged".
    public let key: String
    public let label: String
    public let value: String

    public init(key: String, label: String, value: String) {
        self.key = key
        self.label = label
        self.value = value
    }
}

/// The full, shareable "Taste DNA" content derived from a watch history.
public struct TasteProfile: Hashable, Sendable {
    public let archetype: String
    public let definingGenres: [DefiningGenre]
    public let hottestTakes: [HottestTake]
    public let obsessions: [Obsession]
    public let blindSpots: [BlindSpot]
    public let headlineStats: [HeadlineStat]

    public init(
        archetype: String,
        definingGenres: [DefiningGenre],
        hottestTakes: [HottestTake],
        obsessions: [Obsession],
        blindSpots: [BlindSpot],
        headlineStats: [HeadlineStat]
    ) {
        self.archetype = archetype
        self.definingGenres = definingGenres
        self.hottestTakes = hottestTakes
        self.obsessions = obsessions
        self.blindSpots = blindSpots
        self.headlineStats = headlineStats
    }

    /// The empty profile, returned for a history with no diary entries.
    public static let empty = TasteProfile(
        archetype: "Unwritten",
        definingGenres: [],
        hottestTakes: [],
        obsessions: [],
        blindSpots: [],
        headlineStats: []
    )
}
