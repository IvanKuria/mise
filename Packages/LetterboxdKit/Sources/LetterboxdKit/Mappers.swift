import Foundation
import MiseCore

// MARK: - Wire DTO -> MiseCore mappers
//
// All mappers are defensive: a film with no usable id cannot be mapped (returns
// nil); everything else degrades gracefully to defaults. Date parsing tolerates
// both `yyyy-MM-dd` (diary dates) and ISO8601 timestamps.

enum LetterboxdMappers {

    // MARK: Dates

    /// Date formatters are not `Sendable` and carry mutable state, so we build
    /// fresh instances per call rather than sharing static ones. Parsing is rare
    /// relative to network latency, so this is not a hot path.
    private static func makeDiaryDateFormatter() -> DateFormatter {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .iso8601)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }

    static func parseDate(_ string: String?) -> Date? {
        guard let string, !string.isEmpty else { return nil }
        if let d = makeDiaryDateFormatter().date(from: string) { return d }

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: string) { return d }

        iso.formatOptions = [.withInternetDateTime]
        if let d = iso.date(from: string) { return d }

        return nil
    }

    // MARK: Member

    static func member(_ dto: MemberDTO) -> MemberSummary? {
        guard let id = dto.id else { return nil }
        let username = dto.username ?? id
        return MemberSummary(
            id: id,
            username: username,
            displayName: dto.displayName ?? username,
            avatarURL: dto.avatar?.bestURL
        )
    }

    // MARK: Statistics

    static func statistics(_ dto: MemberStatisticsDTO) -> MemberStatistics {
        var histogram: [Int: Int] = [:]
        for bar in dto.ratingsHistogram ?? [] {
            guard let stars = bar.rating, let rating = Rating(stars: stars) else { continue }
            histogram[rating.halfStars, default: 0] += bar.count ?? 0
        }
        let counts = dto.counts
        return MemberStatistics(
            watchedFilmCount: counts?.watches ?? 0,
            diaryEntryCount: counts?.diaryEntries ?? 0,
            listCount: counts?.lists ?? 0,
            followerCount: counts?.followers ?? 0,
            followingCount: counts?.following ?? 0,
            ratingsHistogram: histogram
        )
    }

    // MARK: Film

    static func film(_ dto: FilmDTO) -> Film? {
        guard let id = dto.id else { return nil }

        let genres: [Genre] = (dto.genres ?? []).compactMap { g in
            guard let gid = g.id, let name = g.name else { return nil }
            return Genre(id: gid, name: name)
        }

        let directors = contributors(in: dto, matching: "director")
        let cast = contributors(in: dto, matching: "actor")

        let countries = (dto.countries ?? []).compactMap { $0.name ?? $0.code }
        let languages = (dto.languages ?? []).compactMap { $0.name ?? $0.code }

        return Film(
            id: id,
            name: dto.name ?? "",
            releaseYear: dto.releaseYear,
            runtimeMinutes: dto.runTime,
            genres: genres,
            directors: directors,
            cast: cast,
            countries: countries,
            languages: languages,
            tmdbID: dto.tmdbID,
            posterURL: dto.poster?.bestURL,
            letterboxdAverageRating: dto.rating,
            letterboxdURL: dto.letterboxdURL
        )
    }

    private static func contributors(in dto: FilmDTO, matching type: String) -> [Person] {
        let contributions = (dto.contributions ?? []).filter {
            $0.type?.lowercased() == type.lowercased()
        }
        return contributions.flatMap { $0.contributors ?? [] }.compactMap { c in
            guard let cid = c.id, let name = c.name else { return nil }
            return Person(id: cid, name: name, characterName: c.characterName)
        }
    }

    // MARK: Log entries

    static func diaryEntry(_ dto: LogEntryDTO) -> DiaryEntry? {
        guard let id = dto.id, let filmDTO = dto.film, let film = film(filmDTO) else { return nil }
        let rating = dto.rating.flatMap { Rating(stars: $0) }
        return DiaryEntry(
            id: id,
            film: film,
            watchedDate: parseDate(dto.diaryDetails?.diaryDate),
            loggedDate: parseDate(dto.whenCreated),
            rating: rating,
            isRewatch: dto.diaryDetails?.rewatch ?? false,
            isLiked: dto.like ?? false,
            review: dto.review?.text,
            tags: (dto.tags2 ?? []).compactMap { $0.displayTag ?? $0.tag }
        )
    }

    // MARK: Watchlist

    static func watchlistItem(_ dto: FilmDTO) -> WatchlistItem? {
        guard let film = film(dto) else { return nil }
        return WatchlistItem(film: film, addedDate: nil)
    }

    // MARK: Lists

    static func filmList(_ dto: ListDTO) -> FilmList? {
        guard let id = dto.id, let name = dto.name else { return nil }
        let films = (dto.entries ?? []).compactMap { $0.film.flatMap(film) }
        return FilmList(
            id: id,
            name: name,
            description: dto.description,
            ranked: dto.ranked ?? false,
            films: films
        )
    }
}
