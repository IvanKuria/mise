import Foundation
import MiseCore
import StatsEngine

/// Builds the shareable `TasteProfile` ("Taste DNA") from a `WatchHistory`.
///
/// Pure and deterministic: it calls `StatsEngine.compute` internally and turns the
/// raw `FilmStats` into framed, card-ready identity content. No I/O, no randomness;
/// all ordering is stabilised by tie-breaking on stable keys.
public enum TasteProfileBuilder {

    // MARK: - Tuning constants (documented heuristics)

    /// Min count for a genre to be eligible as a "defining" genre.
    static let minDefiningGenreCount = 2
    /// A genre is "defining" when its lift (share vs. an even split) is at least this.
    static let definingGenreLiftThreshold = 1.3
    /// Max defining genres returned.
    static let maxDefiningGenres = 5
    /// Min |delta| (in stars) for a rated film to count as a hottest take.
    static let minTakeDelta = 1.0
    /// Max hottest takes returned.
    static let maxHottestTakes = 5
    /// Min films for a director/cast member to count as an obsession.
    static let minPersonObsessionCount = 3
    /// A decade is an obsession when it holds at least this share of dated films.
    static let decadeObsessionShareThreshold = 0.35
    /// Min dated films before decade-obsession detection runs.
    static let minFilmsForDecadeObsession = 5
    /// Max obsessions returned.
    static let maxObsessions = 6

    /// "Mainstream" decades a typical viewer covers; absence is a notable blind spot.
    static let canonicalDecades: [Int] = [1950, 1960, 1970, 1980, 1990, 2000, 2010, 2020]
    /// "Mainstream" genres a typical viewer covers; absence is a notable blind spot.
    static let canonicalGenres: [String] = [
        "Action", "Comedy", "Drama", "Horror", "Documentary", "Animation",
        "Science Fiction", "Romance", "Thriller", "Western",
    ]
    /// Min total films before blind-spot detection runs (avoids flagging gaps for tiny libraries).
    static let minFilmsForBlindSpots = 10
    /// Max blind spots returned.
    static let maxBlindSpots = 4

    // MARK: - Entry point

    public static func build(from history: WatchHistory) -> TasteProfile {
        let stats = StatsEngine.compute(history)
        guard stats.totalLogged > 0 else { return .empty }

        let definingGenres = definingGenres(stats)
        let hottestTakes = hottestTakes(stats)
        let obsessions = obsessions(stats)
        let blindSpots = blindSpots(stats)
        let headlineStats = headlineStats(stats)
        let archetype = archetype(
            stats: stats,
            definingGenres: definingGenres,
            obsessions: obsessions
        )

        return TasteProfile(
            archetype: archetype,
            definingGenres: definingGenres,
            hottestTakes: hottestTakes,
            obsessions: obsessions,
            blindSpots: blindSpots,
            headlineStats: headlineStats
        )
    }

    // MARK: - Defining genres

    /// Top genres by count, weighted by how far above the member's own baseline
    /// (an even split across the genres they watch) they sit. A genre qualifies
    /// when it clears `minDefiningGenreCount` and `definingGenreLiftThreshold`;
    /// the result is ranked by lift desc, then count desc, then name asc.
    static func definingGenres(_ stats: FilmStats) -> [DefiningGenre] {
        let breakdown = stats.genreBreakdown
        let totalTagged = breakdown.values.reduce(0) { $0 + $1.count }
        guard totalTagged > 0 else { return [] }
        let distinctGenres = breakdown.count
        let evenShare = 1.0 / Double(distinctGenres)

        let candidates: [DefiningGenre] = breakdown.compactMap { name, agg in
            guard agg.count >= minDefiningGenreCount else { return nil }
            let share = Double(agg.count) / Double(totalTagged)
            let lift = share / evenShare
            guard lift >= definingGenreLiftThreshold else { return nil }
            return DefiningGenre(
                name: name,
                count: agg.count,
                share: share,
                lift: lift,
                label: genreLabel(name: name, lift: lift)
            )
        }

        let ranked = candidates.sorted { lhs, rhs in
            if lhs.lift != rhs.lift { return lhs.lift > rhs.lift }
            if lhs.count != rhs.count { return lhs.count > rhs.count }
            return lhs.name < rhs.name
        }
        return Array(ranked.prefix(maxDefiningGenres))
    }

    static func genreLabel(name: String, lift: Double) -> String {
        lift >= 2.0 ? "\(name) devotee" : name
    }

    // MARK: - Hottest takes

    /// Reuses `FilmStats.hottestTakes`, keeping only films whose member rating
    /// deviates from the crowd by at least `minTakeDelta`, framed with a direction.
    static func hottestTakes(_ stats: FilmStats) -> [HottestTake] {
        stats.hottestTakes
            .filter { abs($0.delta) >= minTakeDelta }
            .prefix(maxHottestTakes)
            .map { take in
                let direction: TakeDirection = take.delta > 0 ? .lovedItCrowdDidnt : .dislikedItCrowdLoved
                return HottestTake(
                    filmID: take.filmID,
                    filmName: take.filmName,
                    memberStars: take.memberStars,
                    communityStars: take.communityStars,
                    delta: take.delta,
                    direction: direction,
                    blurb: takeBlurb(name: take.filmName, direction: direction)
                )
            }
    }

    static func takeBlurb(name: String, direction: TakeDirection) -> String {
        switch direction {
        case .lovedItCrowdDidnt: return "You loved \(name) — the crowd didn't."
        case .dislikedItCrowdLoved: return "You disliked \(name) — the crowd loved it."
        }
    }

    // MARK: - Obsessions

    /// Most-watched directors and cast (>= `minPersonObsessionCount`) plus decades
    /// the member over-indexes on (>= `decadeObsessionShareThreshold` of dated films).
    /// Ordered by count desc within kind; people before decades; capped.
    static func obsessions(_ stats: FilmStats) -> [Obsession] {
        var result: [Obsession] = []

        let directors = stats.topDirectors
            .filter { $0.count >= minPersonObsessionCount }
            .map { Obsession(kind: .director, key: $0.id, name: $0.name, count: $0.count, label: filmsLabel($0.count)) }

        let cast = stats.topCast
            .filter { $0.count >= minPersonObsessionCount }
            .map { Obsession(kind: .castMember, key: $0.id, name: $0.name, count: $0.count, label: filmsLabel($0.count)) }

        let decadeTotal = stats.decadeBreakdown.values.reduce(0) { $0 + $1.count }
        var decades: [Obsession] = []
        if decadeTotal >= minFilmsForDecadeObsession {
            decades = stats.decadeBreakdown.compactMap { decade, agg in
                let share = Double(agg.count) / Double(decadeTotal)
                guard share >= decadeObsessionShareThreshold else { return nil }
                return Obsession(
                    kind: .decade,
                    key: String(decade),
                    name: "\(decade)s",
                    count: agg.count,
                    label: filmsLabel(agg.count)
                )
            }
        }

        // People are already sorted by StatsEngine (count desc, then rating, then name).
        // Decades sorted by count desc, then decade asc for stability.
        decades.sort { lhs, rhs in
            if lhs.count != rhs.count { return lhs.count > rhs.count }
            return (Int(lhs.key) ?? 0) < (Int(rhs.key) ?? 0)
        }

        result.append(contentsOf: directors)
        result.append(contentsOf: cast)
        result.append(contentsOf: decades)
        return Array(result.prefix(maxObsessions))
    }

    static func filmsLabel(_ count: Int) -> String {
        count == 1 ? "1 film" : "\(count) films"
    }

    // MARK: - Blind spots

    /// Canonical genres/decades the member has near-zero presence in. Only runs
    /// once the library is large enough (`minFilmsForBlindSpots`) to make a gap
    /// meaningful. "Near-zero" means a count of 0. Genres listed before decades;
    /// each list ordered by the canonical ordering; capped.
    static func blindSpots(_ stats: FilmStats) -> [BlindSpot] {
        guard stats.totalLogged >= minFilmsForBlindSpots else { return [] }

        let genreCounts = stats.genreBreakdown
        let genreSpots: [BlindSpot] = canonicalGenres.compactMap { genre in
            let count = genreCounts[genre]?.count ?? 0
            guard count == 0 else { return nil }
            return BlindSpot(kind: .genre, key: genre, name: genre, count: 0, label: "Never logged \(genreArticle(genre))")
        }

        let decadeCounts = stats.decadeBreakdown
        let decadeSpots: [BlindSpot] = canonicalDecades.compactMap { decade in
            let count = decadeCounts[decade]?.count ?? 0
            guard count == 0 else { return nil }
            return BlindSpot(kind: .decade, key: String(decade), name: "\(decade)s", count: 0, label: "Nothing from the \(decade)s")
        }

        return Array((genreSpots + decadeSpots).prefix(maxBlindSpots))
    }

    static func genreArticle(_ genre: String) -> String {
        let vowels: Set<Character> = ["A", "E", "I", "O", "U"]
        let article = (genre.first.map { vowels.contains($0) } ?? false) ? "an" : "a"
        return "\(article) \(genre) film"
    }

    // MARK: - Headline stats

    /// A few punchy numbers: films logged, days of runtime, average rating, and a
    /// percentile-ish contrarian label.
    static func headlineStats(_ stats: FilmStats) -> [HeadlineStat] {
        var result: [HeadlineStat] = []

        result.append(HeadlineStat(key: "filmsLogged", label: "Films logged", value: String(stats.totalLogged)))

        let days = Double(stats.totalRuntimeMinutes) / 1440.0
        result.append(HeadlineStat(key: "daysOfRuntime", label: "Days watching", value: oneDecimal(days)))

        if let avg = averageRating(stats) {
            result.append(HeadlineStat(key: "averageRating", label: "Average rating", value: "\(oneDecimal(avg))★"))
        }

        if let score = stats.contrarianScore {
            result.append(HeadlineStat(key: "contrarian", label: "Contrarian streak", value: contrarianLabel(score)))
        }

        return result
    }

    /// Mean member rating in stars across rated entries, from the histogram.
    static func averageRating(_ stats: FilmStats) -> Double? {
        var sumHalfStars = 0
        var count = 0
        for (halfStars, n) in stats.ratingsHistogram {
            sumHalfStars += halfStars * n
            count += n
        }
        guard count > 0 else { return nil }
        return Double(sumHalfStars) / Double(count) / 2.0
    }

    /// A qualitative, percentile-ish label over the mean rating-vs-crowd delta.
    /// Positive => the member is generous vs. the crowd; negative => harsh.
    static func contrarianLabel(_ score: Double) -> String {
        switch score {
        case ..<(-1.0): return "Ruthless critic"
        case (-1.0)..<(-0.4): return "Tougher than most"
        case (-0.4)...0.4: return "In step with the crowd"
        case 0.4...1.0: return "Easy to please"
        default: return "Eternal optimist"
        }
    }

    static func oneDecimal(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    // MARK: - Archetype

    /// Derives a fun identity label from the dominant signals.
    ///
    /// Rule set (first match wins; documented + deterministic):
    /// 1. **Empty** → handled before this is called (returns `.empty`).
    /// 2. Let `topGenre` = highest-lift defining genre (if any).
    ///    Let `contrarian` = `contrarianScore` (mean member-vs-crowd delta).
    /// 3. **"Arthouse Contrarian"** — strongly contrarian *downward*
    ///    (`contrarian <= -0.5`) AND top genre is an arthouse-leaning genre
    ///    (Drama / Documentary / History / War / Music).
    /// 4. **"Auteur Worshipper"** — has at least one *director* obsession.
    /// 5. **"Decade Time-Traveler"** — has at least one *decade* obsession.
    /// 6. **"Blockbuster Comfort-Watcher"** — generous vs. crowd
    ///    (`contrarian >= 0.5`) AND top genre is a crowd-pleaser
    ///    (Action / Adventure / Comedy / Family / Animation / Science Fiction).
    /// 7. **"Genre Specialist"** — has a defining genre but no stronger signal fired;
    ///    label embeds the genre, e.g. "Horror Specialist".
    /// 8. **"Hot-Take Machine"** — no defining genre, but `|contrarian| >= 0.5`.
    /// 9. **"Eclectic Omnivore"** — fallback for a broad, balanced library.
    static func archetype(
        stats: FilmStats,
        definingGenres: [DefiningGenre],
        obsessions: [Obsession]
    ) -> String {
        let topGenre = definingGenres.first?.name
        let contrarian = stats.contrarianScore ?? 0
        let hasDirectorObsession = obsessions.contains { $0.kind == .director }
        let hasDecadeObsession = obsessions.contains { $0.kind == .decade }

        let arthouseGenres: Set<String> = ["Drama", "Documentary", "History", "War", "Music"]
        let crowdPleasers: Set<String> = ["Action", "Adventure", "Comedy", "Family", "Animation", "Science Fiction"]

        if contrarian <= -0.5, let g = topGenre, arthouseGenres.contains(g) {
            return "Arthouse Contrarian"
        }
        if hasDirectorObsession {
            return "Auteur Worshipper"
        }
        if hasDecadeObsession {
            return "Decade Time-Traveler"
        }
        if contrarian >= 0.5, let g = topGenre, crowdPleasers.contains(g) {
            return "Blockbuster Comfort-Watcher"
        }
        if let g = topGenre {
            return "\(g) Specialist"
        }
        if abs(contrarian) >= 0.5 {
            return "Hot-Take Machine"
        }
        return "Eclectic Omnivore"
    }
}
