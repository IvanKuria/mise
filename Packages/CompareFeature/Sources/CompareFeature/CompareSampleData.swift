import Foundation
import MiseCore

/// Deterministic sample watch histories for previews and tests. Two members who
/// overlap on several films but diverge sharply on a few, plus loved-but-unseen
/// films on each side to seed the poster rows.
public enum CompareSampleData {

    // MARK: Members

    public static let mira = MemberSummary(
        id: "m-mira",
        username: "mira",
        displayName: "Mira",
        avatarURL: nil
    )

    public static let dev = MemberSummary(
        id: "m-dev",
        username: "dev",
        displayName: "Dev",
        avatarURL: nil
    )

    // MARK: Films

    static func film(_ id: String, _ name: String, _ year: Int) -> Film {
        Film(id: id, name: name, releaseYear: year)
    }

    // Shared films (both watch these).
    static let mulholland = film("f-1", "Mulholland Drive", 2001)
    static let theMaster = film("f-2", "The Master", 2012)
    static let burning = film("f-3", "Burning", 2018)
    static let drive = film("f-4", "Drive My Car", 2021)
    static let aftersun = film("f-5", "Aftersun", 2022)
    static let pastLives = film("f-6", "Past Lives", 2023)

    // Mira-only loves (seeds "for them").
    static let portrait = film("f-7", "Portrait of a Lady on Fire", 2019)
    static let inTheMood = film("f-8", "In the Mood for Love", 2000)

    // Dev-only loves (seeds "for you").
    static let stalker = film("f-9", "Stalker", 1979)
    static let parisTexas = film("f-10", "Paris, Texas", 1984)

    // MARK: Histories

    static func entry(_ film: Film, _ halfStars: Int) -> DiaryEntry {
        DiaryEntry(id: "d-\(film.id)", film: film, rating: Rating(halfStars: halfStars))
    }

    /// "Me" — Mira.
    public static let me = WatchHistory(
        member: mira,
        diary: [
            entry(mulholland, 10), // agree-ish
            entry(theMaster, 9),   // she loves it…
            entry(burning, 8),
            entry(drive, 10),      // big disagreement (Dev gives 4)
            entry(aftersun, 9),
            entry(pastLives, 7),
            entry(portrait, 10),   // loved, Dev hasn't seen
            entry(inTheMood, 10),  // loved, Dev hasn't seen
        ]
    )

    /// "Other" — Dev.
    public static let other = WatchHistory(
        member: dev,
        diary: [
            entry(mulholland, 9),
            entry(theMaster, 4),   // big disagreement
            entry(burning, 9),
            entry(drive, 4),       // big disagreement
            entry(aftersun, 8),
            entry(pastLives, 8),
            entry(stalker, 10),    // loved, Mira hasn't seen
            entry(parisTexas, 9),  // loved, Mira hasn't seen
        ]
    )

    /// Two members with no rated film in common (drives the empty state).
    public static let meNoOverlap = WatchHistory(
        member: mira,
        diary: [entry(portrait, 10), entry(inTheMood, 9)]
    )

    public static let otherNoOverlap = WatchHistory(
        member: dev,
        diary: [entry(stalker, 10), entry(parisTexas, 8)]
    )
}
