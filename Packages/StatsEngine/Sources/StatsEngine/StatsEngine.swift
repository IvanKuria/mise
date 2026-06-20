import Foundation
import MiseCore

/// Pure, I/O-free analytics over a `MiseCore.WatchHistory`.
public enum StatsEngine {
    /// Compute the full analytics result for a member's watch history.
    public static func compute(
        _ history: WatchHistory,
        options: StatsOptions = .default
    ) -> FilmStats {
        let diary = history.diary
        let contrarian = contrarian(diary)
        let heatmap = heatmap(diary)

        return FilmStats(
            totalLogged: diary.count,
            rewatchCount: diary.lazy.filter(\.isRewatch).count,
            likedCount: diary.lazy.filter(\.isLiked).count,
            reviewCount: diary.lazy.filter(\.hasReview).count,
            distinctFilmCount: Set(diary.map { $0.film.id }).count,
            ratingsHistogram: ratingsHistogram(diary),
            contrarianScore: contrarian.score,
            hottestTakes: contrarian.takes(maxCount: options.maxHottestTakes),
            genreBreakdown: breakdown(diary) { $0.film.genres.map(\.name) },
            decadeBreakdown: breakdown(diary) { $0.film.decade.map { [$0] } ?? [] },
            countryBreakdown: breakdown(diary) { $0.film.countries },
            languageBreakdown: breakdown(diary) { $0.film.languages },
            topDirectors: people(diary, minCount: options.minDirectorCount) { $0.film.directors },
            topCast: people(diary, minCount: options.minCastCount) { $0.film.cast },
            totalRuntimeMinutes: diary.reduce(0) { $0 + ($1.film.runtimeMinutes ?? 0) },
            runtimeMinutesPerYear: runtimeMinutesPerYear(diary),
            heatmap: heatmap.days,
            longestStreakDays: heatmap.longestStreak,
            currentStreakDays: heatmap.currentStreak,
            filmsPerYear: filmsPerYear(diary),
            filmsPerMonth: filmsPerMonth(diary)
        )
    }

    /// UTC calendar for deterministic date-component extraction.
    static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    static func dayKey(_ date: Date) -> DayKey {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return DayKey(year: c.year!, month: c.month!, day: c.day!)
    }

    static func monthKey(_ date: Date) -> MonthKey {
        let c = calendar.dateComponents([.year, .month], from: date)
        return MonthKey(year: c.year!, month: c.month!)
    }

    static func year(_ date: Date) -> Int {
        calendar.component(.year, from: date)
    }

    // MARK: - Runtime

    static func runtimeMinutesPerYear(_ diary: [DiaryEntry]) -> [Int: Int] {
        var result: [Int: Int] = [:]
        for entry in diary {
            guard let date = entry.watchedDate, let runtime = entry.film.runtimeMinutes else { continue }
            result[year(date), default: 0] += runtime
        }
        return result
    }

    // MARK: - Heatmap

    struct HeatmapResult {
        let days: [DayKey: Int]
        let longestStreak: Int
        let currentStreak: Int
    }

    static func heatmap(_ diary: [DiaryEntry]) -> HeatmapResult {
        var days: [DayKey: Int] = [:]
        for entry in diary {
            guard let date = entry.watchedDate else { continue }
            days[dayKey(date), default: 0] += 1
        }
        let (longest, current) = streaks(Array(days.keys))
        return HeatmapResult(days: days, longestStreak: longest, currentStreak: current)
    }

    /// Longest run of consecutive calendar days, and the run ending at the most
    /// recent watch day (deterministic; not relative to "today").
    static func streaks(_ keys: [DayKey]) -> (longest: Int, current: Int) {
        guard !keys.isEmpty else { return (0, 0) }
        let sorted = keys.sorted()
        // Map each day to a day-number via the UTC calendar for adjacency checks.
        let dayNumbers: [Int] = sorted.map { key in
            var c = DateComponents()
            c.year = key.year; c.month = key.month; c.day = key.day
            let date = calendar.date(from: c)!
            return Int((date.timeIntervalSince1970 / 86_400).rounded())
        }

        var longest = 1
        var run = 1
        var currentRun = 1
        for i in 1..<dayNumbers.count {
            if dayNumbers[i] == dayNumbers[i - 1] + 1 {
                run += 1
            } else {
                run = 1
            }
            longest = max(longest, run)
            currentRun = run // run ending at the latest (last) day
        }
        return (longest, currentRun)
    }

    // MARK: - Time series

    static func filmsPerYear(_ diary: [DiaryEntry]) -> [Int: Int] {
        var result: [Int: Int] = [:]
        for entry in diary {
            guard let date = entry.watchedDate else { continue }
            result[year(date), default: 0] += 1
        }
        return result
    }

    static func filmsPerMonth(_ diary: [DiaryEntry]) -> [MonthKey: Int] {
        var result: [MonthKey: Int] = [:]
        for entry in diary {
            guard let date = entry.watchedDate else { continue }
            result[monthKey(date), default: 0] += 1
        }
        return result
    }

    // MARK: - Ratings

    static func ratingsHistogram(_ diary: [DiaryEntry]) -> [Int: Int] {
        var histogram: [Int: Int] = [:]
        for entry in diary {
            guard let rating = entry.rating else { continue }
            histogram[rating.halfStars, default: 0] += 1
        }
        return histogram
    }

    // MARK: - Breakdowns

    /// Group diary entries into buckets keyed by `keys(entry)` (an entry may
    /// contribute to several buckets, e.g. multiple genres), counting every
    /// appearance and averaging member ratings (in stars) over rated entries.
    static func breakdown<Key: Hashable>(
        _ diary: [DiaryEntry],
        keys: (DiaryEntry) -> [Key]
    ) -> [Key: CountAverage] {
        var counts: [Key: Int] = [:]
        var ratingSums: [Key: Double] = [:]
        var ratingCounts: [Key: Int] = [:]
        for entry in diary {
            for key in keys(entry) {
                counts[key, default: 0] += 1
                if let rating = entry.rating {
                    ratingSums[key, default: 0] += rating.stars
                    ratingCounts[key, default: 0] += 1
                }
            }
        }
        var result: [Key: CountAverage] = [:]
        for (key, count) in counts {
            let avg: Double?
            if let rc = ratingCounts[key], rc > 0 {
                avg = ratingSums[key]! / Double(rc)
            } else {
                avg = nil
            }
            result[key] = CountAverage(count: count, averageRating: avg)
        }
        return result
    }

    // MARK: - Contrarian

    /// Per-film deviations of member rating from the Letterboxd community average.
    struct ContrarianResult {
        let deltas: [FilmTakeDelta]

        /// Mean delta, `nil` when no eligible films.
        var score: Double? {
            guard !deltas.isEmpty else { return nil }
            return deltas.reduce(0) { $0 + $1.delta } / Double(deltas.count)
        }

        /// Films with the largest |delta| first; ties broken by filmID for stability.
        func takes(maxCount: Int) -> [FilmTakeDelta] {
            let sorted = deltas.sorted { lhs, rhs in
                if abs(lhs.delta) != abs(rhs.delta) { return abs(lhs.delta) > abs(rhs.delta) }
                return lhs.filmID < rhs.filmID
            }
            return Array(sorted.prefix(max(0, maxCount)))
        }
    }

    static func contrarian(_ diary: [DiaryEntry]) -> ContrarianResult {
        var deltas: [FilmTakeDelta] = []
        for entry in diary {
            guard let rating = entry.rating,
                  let community = entry.film.letterboxdAverageRating else { continue }
            deltas.append(
                FilmTakeDelta(
                    filmID: entry.film.id,
                    filmName: entry.film.name,
                    memberStars: rating.stars,
                    communityStars: community
                )
            )
        }
        return ContrarianResult(deltas: deltas)
    }

    // MARK: - People

    /// Aggregate per person across `persons(entry)`, filtered to `minCount`
    /// appearances, sorted by count desc, then averageRating desc (nil last),
    /// then name asc for stable, deterministic ordering.
    static func people(
        _ diary: [DiaryEntry],
        minCount: Int,
        persons: (DiaryEntry) -> [Person]
    ) -> [NamedAggregate] {
        var counts: [String: Int] = [:]
        var names: [String: String] = [:]
        var ratingSums: [String: Double] = [:]
        var ratingCounts: [String: Int] = [:]
        for entry in diary {
            // De-duplicate the same person id within a single entry.
            var seen: Set<String> = []
            for person in persons(entry) where seen.insert(person.id).inserted {
                counts[person.id, default: 0] += 1
                names[person.id] = person.name
                if let rating = entry.rating {
                    ratingSums[person.id, default: 0] += rating.stars
                    ratingCounts[person.id, default: 0] += 1
                }
            }
        }

        let aggregates: [NamedAggregate] = counts.compactMap { id, count in
            guard count >= minCount else { return nil }
            let avg: Double?
            if let rc = ratingCounts[id], rc > 0 {
                avg = ratingSums[id]! / Double(rc)
            } else {
                avg = nil
            }
            return NamedAggregate(id: id, name: names[id] ?? id, count: count, averageRating: avg)
        }

        return aggregates.sorted { lhs, rhs in
            if lhs.count != rhs.count { return lhs.count > rhs.count }
            let l = lhs.averageRating ?? -.infinity
            let r = rhs.averageRating ?? -.infinity
            if l != r { return l > r }
            return lhs.name < rhs.name
        }
    }
}
