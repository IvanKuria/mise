import Foundation
import Testing
import MiseCore
@testable import TasteProfile

// MARK: - Fixture helpers

private let member = MemberSummary(id: "m1", username: "cinephile", displayName: "Cinephile")

private func genre(_ name: String) -> Genre { Genre(id: name.lowercased(), name: name) }

private func film(
    _ id: String,
    name: String? = nil,
    year: Int? = nil,
    runtime: Int? = nil,
    genres: [String] = [],
    directors: [Person] = [],
    cast: [Person] = [],
    community: Double? = nil
) -> Film {
    Film(
        id: id,
        name: name ?? id,
        releaseYear: year,
        runtimeMinutes: runtime,
        genres: genres.map(genre),
        directors: directors,
        cast: cast,
        letterboxdAverageRating: community
    )
}

private func entry(
    _ id: String,
    film: Film,
    stars: Double? = nil,
    watched: Date? = Date(timeIntervalSince1970: 1_700_000_000)
) -> DiaryEntry {
    DiaryEntry(
        id: id,
        film: film,
        watchedDate: watched,
        rating: stars.flatMap { Rating(stars: $0) }
    )
}

private func history(_ diary: [DiaryEntry]) -> WatchHistory {
    WatchHistory(member: member, diary: diary)
}

// MARK: - Empty history

@Test
func emptyHistoryReturnsEmptyProfile() {
    let profile = TasteProfileBuilder.build(from: history([]))
    #expect(profile == .empty)
    #expect(profile.archetype == "Unwritten")
    #expect(profile.definingGenres.isEmpty)
    #expect(profile.hottestTakes.isEmpty)
    #expect(profile.obsessions.isEmpty)
    #expect(profile.blindSpots.isEmpty)
    #expect(profile.headlineStats.isEmpty)
}

// MARK: - Defining genres

@Test
func definingGenresRankedByLiftAndLabeled() {
    // 6 horror, 2 drama, 1 comedy. Horror is hugely over-indexed.
    var diary: [DiaryEntry] = []
    for i in 0..<6 { diary.append(entry("h\(i)", film: film("hf\(i)", genres: ["Horror"]))) }
    for i in 0..<2 { diary.append(entry("d\(i)", film: film("df\(i)", genres: ["Drama"]))) }
    diary.append(entry("c0", film: film("cf0", genres: ["Comedy"])))

    let profile = TasteProfileBuilder.build(from: history(diary))
    let names = profile.definingGenres.map(\.name)

    // Comedy has count 1 (< min 2) so excluded. Horror first (highest lift).
    #expect(names.first == "Horror")
    #expect(!names.contains("Comedy"))
    // Horror lift = (6/9) / (1/3) = 2.0 -> "devotee" label.
    let horror = profile.definingGenres.first { $0.name == "Horror" }
    #expect(horror?.label == "Horror devotee")
    #expect((horror?.lift ?? 0) > (profile.definingGenres.last?.lift ?? 0) || profile.definingGenres.count == 1)
}

@Test
func balancedLibraryHasNoDefiningGenre() {
    // Even spread across 3 genres -> lift ~1.0, below threshold.
    var diary: [DiaryEntry] = []
    for (i, g) in ["Horror", "Drama", "Comedy"].enumerated() {
        for j in 0..<3 { diary.append(entry("\(i)-\(j)", film: film("f\(i)-\(j)", genres: [g]))) }
    }
    let profile = TasteProfileBuilder.build(from: history(diary))
    #expect(profile.definingGenres.isEmpty)
}

// MARK: - Hottest takes direction

@Test
func hottestTakesCarryDirectionAndFraming() {
    let loved = film("loved", name: "Mandy", community: 3.0)        // member 5 -> +2
    let hated = film("hated", name: "Avatar", community: 4.5)       // member 1 -> -3.5
    let minor = film("minor", name: "Meh", community: 3.0)          // member 3.5 -> +0.5 (below min)
    let diary = [
        entry("a", film: loved, stars: 5.0),
        entry("b", film: hated, stars: 1.0),
        entry("c", film: minor, stars: 3.5),
    ]
    let profile = TasteProfileBuilder.build(from: history(diary))

    // Minor take filtered out (|delta| 0.5 < 1.0).
    #expect(!profile.hottestTakes.contains { $0.filmID == "minor" })

    let lovedTake = profile.hottestTakes.first { $0.filmID == "loved" }
    #expect(lovedTake?.direction == .lovedItCrowdDidnt)
    #expect(lovedTake?.blurb == "You loved Mandy — the crowd didn't.")

    let hatedTake = profile.hottestTakes.first { $0.filmID == "hated" }
    #expect(hatedTake?.direction == .dislikedItCrowdLoved)
    #expect(hatedTake?.blurb == "You disliked Avatar — the crowd loved it.")

    // Sorted by |delta| desc: hated (3.5) before loved (2.0).
    #expect(profile.hottestTakes.first?.filmID == "hated")
}

// MARK: - Obsession detection

@Test
func directorObsessionDetected() {
    let lynch = Person(id: "lynch", name: "David Lynch")
    var diary: [DiaryEntry] = []
    for i in 0..<4 { diary.append(entry("l\(i)", film: film("lf\(i)", genres: ["Drama"], directors: [lynch]))) }
    // Some filler so it's not pure-Lynch.
    diary.append(entry("x", film: film("xf", genres: ["Comedy"])))

    let profile = TasteProfileBuilder.build(from: history(diary))
    let directorObs = profile.obsessions.first { $0.kind == .director }
    #expect(directorObs?.name == "David Lynch")
    #expect(directorObs?.count == 4)
    #expect(directorObs?.label == "4 films")
}

@Test
func decadeObsessionDetected() {
    // 6 films from the 1980s, 2 from 2010s -> 1980s share = 0.75 >= 0.35.
    var diary: [DiaryEntry] = []
    for i in 0..<6 { diary.append(entry("e\(i)", film: film("ef\(i)", year: 1985, genres: ["Drama"]))) }
    for i in 0..<2 { diary.append(entry("n\(i)", film: film("nf\(i)", year: 2015, genres: ["Drama"]))) }

    let profile = TasteProfileBuilder.build(from: history(diary))
    let decadeObs = profile.obsessions.first { $0.kind == .decade }
    #expect(decadeObs?.name == "1980s")
    #expect(decadeObs?.key == "1980")
    #expect(decadeObs?.count == 6)
}

@Test
func noObsessionBelowThreshold() {
    // 2 Lynch films (< 3), spread decades -> no obsessions.
    let lynch = Person(id: "lynch", name: "David Lynch")
    var diary: [DiaryEntry] = []
    diary.append(entry("l0", film: film("lf0", year: 1980, genres: ["Drama"], directors: [lynch])))
    diary.append(entry("l1", film: film("lf1", year: 1990, genres: ["Drama"], directors: [lynch])))
    diary.append(entry("o0", film: film("of0", year: 2000, genres: ["Comedy"])))
    diary.append(entry("o1", film: film("of1", year: 2010, genres: ["Action"])))

    let profile = TasteProfileBuilder.build(from: history(diary))
    #expect(profile.obsessions.isEmpty)
}

// MARK: - Blind spots

@Test
func blindSpotsFlagMissingCanonicalGenres() {
    // 12 films, all Drama, all from the 2010s -> many canonical gaps.
    var diary: [DiaryEntry] = []
    for i in 0..<12 { diary.append(entry("d\(i)", film: film("df\(i)", year: 2015, genres: ["Drama"]))) }

    let profile = TasteProfileBuilder.build(from: history(diary))
    #expect(!profile.blindSpots.isEmpty)
    // Drama is present, so never a blind spot.
    #expect(!profile.blindSpots.contains { $0.kind == .genre && $0.name == "Drama" })
    // Action is a canonical genre and absent.
    #expect(profile.blindSpots.contains { $0.kind == .genre && $0.name == "Action" })
    // Article handling: Action -> "an Action film".
    let action = profile.blindSpots.first { $0.name == "Action" }
    #expect(action?.label == "Never logged an Action film")
}

@Test
func blindSpotsSkippedForSmallLibrary() {
    // Only 5 films (< 10) -> no blind spots even though gaps exist.
    var diary: [DiaryEntry] = []
    for i in 0..<5 { diary.append(entry("d\(i)", film: film("df\(i)", year: 2015, genres: ["Drama"]))) }
    let profile = TasteProfileBuilder.build(from: history(diary))
    #expect(profile.blindSpots.isEmpty)
}

// MARK: - Headline stats

@Test
func headlineStatsArePunchyNumbers() {
    let diary = [
        entry("a", film: film("fa", runtime: 120, genres: ["Drama"], community: 3.0), stars: 4.0),
        entry("b", film: film("fb", runtime: 120, genres: ["Drama"], community: 3.0), stars: 5.0),
    ]
    let profile = TasteProfileBuilder.build(from: history(diary))
    let byKey = Dictionary(uniqueKeysWithValues: profile.headlineStats.map { ($0.key, $0.value) })

    #expect(byKey["filmsLogged"] == "2")
    // 240 minutes / 1440 = 0.166... -> "0.2"
    #expect(byKey["daysOfRuntime"] == "0.2")
    // avg (4 + 5)/2 = 4.5 -> "4.5★"
    #expect(byKey["averageRating"] == "4.5★")
    #expect(byKey["contrarian"] != nil)
}

// MARK: - Archetype rules

@Test
func archetypeArthouseContrarian() {
    // Drama-dominant + harsh vs crowd.
    var diary: [DiaryEntry] = []
    for i in 0..<6 { diary.append(entry("d\(i)", film: film("df\(i)", year: 1990 + i, genres: ["Drama"], community: 4.5), stars: 2.0)) }
    diary.append(entry("c0", film: film("cf0", year: 2001, genres: ["Comedy"], community: 3.0), stars: 3.0))

    let profile = TasteProfileBuilder.build(from: history(diary))
    #expect(profile.definingGenres.first?.name == "Drama")
    #expect((profile.archetype) == "Arthouse Contrarian")
}

@Test
func archetypeAuteurWorshipper() {
    // Director obsession, but not arthouse-contrarian (ratings near crowd, mixed genres).
    let nolan = Person(id: "nolan", name: "Christopher Nolan")
    var diary: [DiaryEntry] = []
    for i in 0..<4 { diary.append(entry("n\(i)", film: film("nf\(i)", year: 2010 + i, genres: ["Thriller"], directors: [nolan], community: 4.0), stars: 4.0)) }
    diary.append(entry("x", film: film("xf", year: 2005, genres: ["Comedy"], community: 3.5), stars: 3.5))

    let profile = TasteProfileBuilder.build(from: history(diary))
    #expect(profile.obsessions.contains { $0.kind == .director })
    #expect(profile.archetype == "Auteur Worshipper")
}

@Test
func archetypeDecadeTimeTraveler() {
    // Decade obsession, no director obsession, ratings near crowd.
    var diary: [DiaryEntry] = []
    for i in 0..<6 { diary.append(entry("e\(i)", film: film("ef\(i)", year: 1975, genres: ["Comedy"], community: 3.5), stars: 3.5)) }
    for i in 0..<2 { diary.append(entry("n\(i)", film: film("nf\(i)", year: 2015, genres: ["Action"], community: 3.5), stars: 3.5)) }

    let profile = TasteProfileBuilder.build(from: history(diary))
    #expect(!profile.obsessions.contains { $0.kind == .director })
    #expect(profile.obsessions.contains { $0.kind == .decade })
    #expect(profile.archetype == "Decade Time-Traveler")
}

@Test
func archetypeBlockbusterComfortWatcher() {
    // Action-dominant + generous vs crowd, no person/decade obsession.
    var diary: [DiaryEntry] = []
    // Spread directors/years so no obsessions fire.
    for i in 0..<6 {
        let d = Person(id: "dir\(i)", name: "Dir \(i)")
        diary.append(entry("a\(i)", film: film("af\(i)", year: 1980 + i * 6, genres: ["Action"], directors: [d], community: 3.0), stars: 5.0))
    }
    diary.append(entry("c0", film: film("cf0", year: 2003, genres: ["Drama"], community: 3.0), stars: 4.0))

    let profile = TasteProfileBuilder.build(from: history(diary))
    #expect(profile.definingGenres.first?.name == "Action")
    #expect(!profile.obsessions.contains { $0.kind == .director })
    #expect(profile.archetype == "Blockbuster Comfort-Watcher")
}

@Test
func archetypeGenreSpecialist() {
    // Horror-dominant, ratings near crowd, no obsessions.
    var diary: [DiaryEntry] = []
    for i in 0..<6 {
        let d = Person(id: "dir\(i)", name: "Dir \(i)")
        diary.append(entry("h\(i)", film: film("hf\(i)", year: 1980 + i * 6, genres: ["Horror"], directors: [d], community: 3.5), stars: 3.5))
    }
    diary.append(entry("d0", film: film("df0", year: 2003, genres: ["Drama"], community: 3.5), stars: 3.5))

    let profile = TasteProfileBuilder.build(from: history(diary))
    #expect(profile.definingGenres.first?.name == "Horror")
    #expect(profile.obsessions.isEmpty)
    #expect(profile.archetype == "Horror Specialist")
}

@Test
func archetypeHotTakeMachine() {
    // No defining genre (balanced), but harsh vs crowd.
    var diary: [DiaryEntry] = []
    for (i, g) in ["Horror", "Drama", "Comedy"].enumerated() {
        for j in 0..<3 {
            let d = Person(id: "dir\(i)\(j)", name: "Dir \(i)\(j)")
            diary.append(entry("\(i)-\(j)", film: film("f\(i)-\(j)", year: 1980 + i * 10 + j, genres: [g], directors: [d], community: 4.5), stars: 2.0))
        }
    }
    let profile = TasteProfileBuilder.build(from: history(diary))
    #expect(profile.definingGenres.isEmpty)
    #expect(profile.archetype == "Hot-Take Machine")
}

@Test
func archetypeEclecticOmnivore() {
    // Balanced genres, ratings in step with crowd, no obsessions.
    var diary: [DiaryEntry] = []
    for (i, g) in ["Horror", "Drama", "Comedy"].enumerated() {
        for j in 0..<3 {
            let d = Person(id: "dir\(i)\(j)", name: "Dir \(i)\(j)")
            diary.append(entry("\(i)-\(j)", film: film("f\(i)-\(j)", year: 1980 + i * 10 + j, genres: [g], directors: [d], community: 3.5), stars: 3.5))
        }
    }
    let profile = TasteProfileBuilder.build(from: history(diary))
    #expect(profile.definingGenres.isEmpty)
    #expect(profile.obsessions.isEmpty)
    #expect(profile.archetype == "Eclectic Omnivore")
}

// MARK: - Determinism

@Test
func buildIsDeterministic() {
    var diary: [DiaryEntry] = []
    for i in 0..<6 { diary.append(entry("h\(i)", film: film("hf\(i)", year: 1985, genres: ["Horror"], community: 3.0), stars: 5.0)) }
    let h = history(diary)
    #expect(TasteProfileBuilder.build(from: h) == TasteProfileBuilder.build(from: h))
}
