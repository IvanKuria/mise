import Foundation
import MiseCore
import SwiftSoup

/// Pure HTML -> model parsers for Letterboxd public pages. No network here so
/// they can be unit-tested directly against saved fixtures.
enum LetterboxdParser {

    // MARK: - Pagination

    /// The highest page number linked in the `paginate-pages` block, or 1 when
    /// there is no pagination (single page).
    static func totalPages(in html: String) throws -> Int {
        let doc = try SwiftSoup.parse(html)
        let pages = try doc.select("div.paginate-pages li.paginate-page a")
        let numbers = try pages.compactMap { Int(try $0.text().trimmingCharacters(in: .whitespaces)) }
        return numbers.max() ?? 1
    }

    // MARK: - Profile

    static func member(_ html: String, username: String) throws -> MemberSummary {
        let doc = try SwiftSoup.parse(html)

        // Display name lives in the header; fall back to the username.
        var displayName = username
        if let label = try doc.select("h1.person-display-name .displayname .label").first() {
            let text = try label.text().trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty { displayName = text }
        } else if let dn = try doc.select(".displayname").first() {
            let text = try dn.text().trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty { displayName = text }
        }

        // Avatar image.
        var avatarURL: URL?
        if let img = try doc.select("div.profile-avatar img").first() {
            let src = try img.attr("src")
            if !src.isEmpty { avatarURL = LetterboxdURLs.resolve(src) }
        }

        return MemberSummary(id: username, username: username, displayName: displayName, avatarURL: avatarURL)
    }

    /// Parse the profile-header statistics (Films / This year / Lists / Following
    /// / Followers). Counts not present are left at their defaults.
    static func statistics(_ html: String) throws -> MemberStatistics {
        let doc = try SwiftSoup.parse(html)
        var byLabel: [String: Int] = [:]
        for stat in try doc.select("h4.profile-statistic") {
            let valueText = try stat.select("span.value").first()?.text() ?? ""
            let label = (try stat.select("span.definition").first()?.text() ?? "")
                .lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            let value = Int(valueText.replacingOccurrences(of: ",", with: "")) ?? 0
            if !label.isEmpty { byLabel[label] = value }
        }
        return MemberStatistics(
            watchedFilmCount: byLabel["films"] ?? 0,
            diaryEntryCount: 0,
            listCount: byLabel["lists"] ?? 0,
            followerCount: byLabel["followers"] ?? 0,
            followingCount: byLabel["following"] ?? 0,
            ratingsHistogram: [:]
        )
    }

    // MARK: - Diary

    static func diaryEntries(_ html: String) throws -> [DiaryEntry] {
        let doc = try SwiftSoup.parse(html)
        var entries: [DiaryEntry] = []
        for row in try doc.select("tr.diary-entry-row") {
            guard let entry = try parseDiaryRow(row) else { continue }
            entries.append(entry)
        }
        return entries
    }

    private static func parseDiaryRow(_ row: Element) throws -> DiaryEntry? {
        // Film identity comes from the LazyPoster react-component.
        guard let poster = try row.select("div.react-component[data-item-slug]").first() else { return nil }
        let slug = try poster.attr("data-item-slug")
        guard !slug.isEmpty else { return nil }

        let displayName = try poster.attr("data-item-name") // e.g. "Toy Story 5 (2026)"
        let name = try row.select("h2.primaryname a").first()?.text()
            ?? stripYear(from: displayName)
        let year = parseYear(from: try row.select("td.col-releaseyear span").first()?.text())
            ?? parseYear(parenthesizedIn: displayName)

        // Rating: prefer the rateit input (0...10, 0 == unrated), fall back to the
        // `rated-N` span class. Class N maps DIRECTLY to Rating(halfStars: N).
        var rating: Rating?
        if let input = try row.select("input.rateit-field").first(),
           let value = Int(try input.attr("value")), value > 0 {
            rating = Rating(halfStars: value)
        } else {
            rating = ratingFromClass(try row.select("td.col-rating span.rating").first())
        }

        // Rewatch: the cell carries `icon-status-off` when NOT a rewatch.
        let rewatchCell = try row.select("td.col-rewatch").first()
        let isRewatch = !((rewatchCell?.hasClass("icon-status-off")) ?? true)

        // Like: the `icon-liked` span is present only when liked.
        let isLiked = !(try row.select("td.col-like span.icon-liked").isEmpty())

        // Review present?
        let hasReview = !(try row.select("td.col-review a").isEmpty())

        // Watched date from the daydate href: /{user}/diary/films/for/YYYY/MM/DD/
        let dayHref = try row.select("a.daydate").first()?.attr("href") ?? ""
        let watched = parseDiaryDate(fromHref: dayHref)

        let viewingID = try poster.attr("data-postered-identifier") // stable-ish
        let id = try { () -> String in
            let attr = try row.attr("data-viewing-id")
            return attr.isEmpty ? "\(slug)-\(viewingID.hashValue)" : attr
        }()

        let film = Film(
            id: slug,
            name: name,
            releaseYear: year,
            letterboxdURL: LetterboxdURLs.resolve("/film/\(slug)/")
        )
        return DiaryEntry(
            id: id,
            film: film,
            watchedDate: watched,
            rating: rating,
            isRewatch: isRewatch,
            isLiked: isLiked,
            review: hasReview ? "" : nil
        )
    }

    // MARK: - Films grid

    /// Films from the `/{user}/films/` grid: slug, name, year, rating (where the
    /// owner rated it), like flag.
    static func filmsGrid(_ html: String) throws -> [DiaryEntry] {
        let doc = try SwiftSoup.parse(html)
        var entries: [DiaryEntry] = []
        for item in try doc.select("li.griditem") {
            guard let poster = try item.select("div.react-component[data-item-slug]").first() else { continue }
            let slug = try poster.attr("data-item-slug")
            guard !slug.isEmpty else { continue }
            let displayName = try poster.attr("data-item-name")
            let name = stripYear(from: displayName)
            let year = parseYear(parenthesizedIn: displayName)

            let rating = ratingFromClass(try item.select("p.poster-viewingdata span.rating").first())
            let isLiked = !(try item.select("p.poster-viewingdata span.icon-liked").isEmpty())

            let film = Film(
                id: slug,
                name: name,
                releaseYear: year,
                letterboxdURL: LetterboxdURLs.resolve("/film/\(slug)/")
            )
            entries.append(
                DiaryEntry(id: slug, film: film, rating: rating, isLiked: isLiked)
            )
        }
        return entries
    }

    // MARK: - Watchlist

    static func watchlist(_ html: String) throws -> [WatchlistItem] {
        let doc = try SwiftSoup.parse(html)
        var items: [WatchlistItem] = []
        for item in try doc.select("li.griditem") {
            guard let poster = try item.select("div.react-component[data-item-slug]").first() else { continue }
            let slug = try poster.attr("data-item-slug")
            guard !slug.isEmpty else { continue }
            let displayName = try poster.attr("data-item-name")
            let film = Film(
                id: slug,
                name: stripYear(from: displayName),
                releaseYear: parseYear(parenthesizedIn: displayName),
                letterboxdURL: LetterboxdURLs.resolve("/film/\(slug)/")
            )
            items.append(WatchlistItem(film: film))
        }
        return items
    }

    // MARK: - Lists

    static func lists(_ html: String) throws -> [FilmList] {
        let doc = try SwiftSoup.parse(html)
        var result: [FilmList] = []
        for article in try doc.select("article.list-summary") {
            let id = try article.attr("data-film-list-id")
            guard let nameLink = try article.select("h2.name a").first() else { continue }
            let name = try nameLink.text().trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { continue }

            var description: String?
            if let notes = try article.select("div.notes").first() {
                let text = try notes.text().trimmingCharacters(in: .whitespacesAndNewlines)
                if !text.isEmpty { description = text }
            }
            let ranked = !(try article.select(".numbered-list").isEmpty())
            let listID = id.isEmpty ? name : id
            result.append(FilmList(id: listID, name: name, description: description, ranked: ranked))
        }
        return result
    }

    // MARK: - Helpers

    /// `rated-N` class (N = half-stars 1...10) -> Rating(halfStars: N).
    static func ratingFromClass(_ span: Element?) -> Rating? {
        guard let span else { return nil }
        guard let classes = try? span.classNames() else { return nil }
        for cls in classes where cls.hasPrefix("rated-") {
            if let n = Int(cls.dropFirst("rated-".count)) { return Rating(halfStars: n) }
        }
        return nil
    }

    static func stripYear(from displayName: String) -> String {
        // "Toy Story 5 (2026)" -> "Toy Story 5"
        guard let open = displayName.lastIndex(of: "(") else { return displayName }
        let prefix = displayName[..<open].trimmingCharacters(in: .whitespaces)
        return prefix.isEmpty ? displayName : prefix
    }

    static func parseYear(from text: String?) -> Int? {
        guard let t = text?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty else { return nil }
        return Int(t)
    }

    static func parseYear(parenthesizedIn displayName: String) -> Int? {
        guard let open = displayName.lastIndex(of: "("),
              let close = displayName.lastIndex(of: ")"), open < close else { return nil }
        let inner = displayName[displayName.index(after: open)..<close]
        return Int(inner.trimmingCharacters(in: .whitespaces))
    }

    /// Parse `/{user}/diary/films/for/2026/06/16/` -> Date (UTC, midday).
    static func parseDiaryDate(fromHref href: String) -> Date? {
        let nums = href.split(separator: "/").compactMap { Int($0) }
        // expect [..., year, month, day] with plausible ranges
        guard nums.count >= 3 else { return nil }
        let day = nums[nums.count - 1]
        let month = nums[nums.count - 2]
        let year = nums[nums.count - 3]
        guard year > 1900, (1...12).contains(month), (1...31).contains(day) else { return nil }
        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.day = day; comps.hour = 12
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal.date(from: comps)
    }
}
