import Testing
import TasteProfile
@testable import TasteCardFeature

@Suite("TasteCardContent projection")
struct TasteCardContentTests {

    private func genre(_ name: String, label: String, count: Int = 5, lift: Double = 1.5) -> DefiningGenre {
        DefiningGenre(name: name, count: count, share: 0.2, lift: lift, label: label)
    }

    private func take(_ name: String, blurb: String) -> HottestTake {
        HottestTake(filmID: name, filmName: name, memberStars: 5, communityStars: 3, delta: 2, direction: .lovedItCrowdDidnt, blurb: blurb)
    }

    @Test("Empty profile yields the unwritten archetype with its tagline and no chips")
    func emptyProfile() {
        let content = TasteCardContent.make(from: .empty)
        #expect(content.archetype == "Unwritten")
        #expect(content.tagline == "A blank reel, waiting")
        #expect(content.genreChips.isEmpty)
        #expect(content.takeBlurbs.isEmpty)
        #expect(content.stats.isEmpty)
        #expect(content.obsessionLine == nil)
        #expect(content.masthead == "MISE")
    }

    @Test("Genre chips prefer the label and are capped at the card maximum")
    func genreChips() {
        let profile = TasteProfile(
            archetype: "Eclectic Omnivore",
            definingGenres: [
                genre("Drama", label: "Drama devotee"),
                genre("Horror", label: "Horror"),
                genre("Comedy", label: "Comedy"),
                genre("Action", label: "Action"),
                genre("Western", label: "Western"),
            ],
            hottestTakes: [], obsessions: [], blindSpots: [], headlineStats: []
        )
        let content = TasteCardContent.make(from: profile)
        #expect(content.genreChips.count == TasteCardContent.maxGenreChips)
        #expect(content.genreChips.first == "Drama devotee")
    }

    @Test("Genre chip falls back to name when label is empty")
    func genreChipFallback() {
        let profile = TasteProfile(
            archetype: "X", definingGenres: [genre("Noir", label: "")],
            hottestTakes: [], obsessions: [], blindSpots: [], headlineStats: []
        )
        #expect(TasteCardContent.make(from: profile).genreChips == ["Noir"])
    }

    @Test("Take blurbs are capped at two")
    func takeBlurbsCap() {
        let profile = TasteProfile(
            archetype: "X", definingGenres: [],
            hottestTakes: [
                take("A", blurb: "blurb A"),
                take("B", blurb: "blurb B"),
                take("C", blurb: "blurb C"),
            ],
            obsessions: [], blindSpots: [], headlineStats: []
        )
        let content = TasteCardContent.make(from: profile)
        #expect(content.takeBlurbs == ["blurb A", "blurb B"])
    }

    @Test("Stats are capped at four and preserve value/label")
    func statsCap() {
        let stats = (0..<6).map { HeadlineStat(key: "k\($0)", label: "L\($0)", value: "V\($0)") }
        let profile = TasteProfile(
            archetype: "X", definingGenres: [], hottestTakes: [],
            obsessions: [], blindSpots: [], headlineStats: stats
        )
        let content = TasteCardContent.make(from: profile)
        #expect(content.stats.count == TasteCardContent.maxStats)
        #expect(content.stats.first?.value == "V0")
        #expect(content.stats.first?.label == "L0")
    }

    @Test("Director obsession is favored over a decade and framed as a line")
    func obsessionPrefersDirector() {
        let profile = TasteProfile(
            archetype: "X", definingGenres: [], hottestTakes: [],
            obsessions: [
                Obsession(kind: .decade, key: "1980", name: "1980s", count: 30, label: "30 films"),
                Obsession(kind: .director, key: "p1", name: "David Lynch", count: 7, label: "7 films"),
            ],
            blindSpots: [], headlineStats: []
        )
        #expect(TasteCardContent.make(from: profile).obsessionLine == "Keeps returning to David Lynch · 7 films")
    }

    @Test("Decade obsession line is used when no people are present")
    func obsessionDecade() {
        let profile = TasteProfile(
            archetype: "X", definingGenres: [], hottestTakes: [],
            obsessions: [Obsession(kind: .decade, key: "1970", name: "1970s", count: 12, label: "12 films")],
            blindSpots: [], headlineStats: []
        )
        #expect(TasteCardContent.make(from: profile).obsessionLine == "Lives in the 1970s · 12 films")
    }

    @Test("Cast obsession line is framed distinctly")
    func obsessionCast() {
        let profile = TasteProfile(
            archetype: "X", definingGenres: [], hottestTakes: [],
            obsessions: [Obsession(kind: .castMember, key: "c1", name: "Toni Collette", count: 4, label: "4 films")],
            blindSpots: [], headlineStats: []
        )
        #expect(TasteCardContent.make(from: profile).obsessionLine == "Can't quit Toni Collette · 4 films")
    }

    @Test("Genre Specialist family gets the specialist tagline")
    func specialistTagline() {
        #expect(TasteCardContent.tagline(for: "Horror Specialist") == "Knows one world deeply")
    }

    @Test("Unknown archetype gets the generic tagline")
    func unknownTagline() {
        #expect(TasteCardContent.tagline(for: "Mystery Label") == "A taste all your own")
    }

    @Test("Known archetypes each map to a non-empty distinct tagline")
    func knownTaglines() {
        let names = [
            "Arthouse Contrarian", "Auteur Worshipper", "Decade Time-Traveler",
            "Blockbuster Comfort-Watcher", "Hot-Take Machine", "Eclectic Omnivore",
        ]
        let taglines = names.map(TasteCardContent.tagline(for:))
        #expect(taglines.allSatisfy { !$0.isEmpty })
        #expect(Set(taglines).count == names.count)
    }
}
