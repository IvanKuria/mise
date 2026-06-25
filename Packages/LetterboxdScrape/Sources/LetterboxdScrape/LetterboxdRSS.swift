import Foundation
import MiseCore

/// Parses a member's public RSS feed (`/{user}/rss/`) into `DiaryEntry`s.
///
/// RSS is the most reliable public source: it is not Cloudflare-challenged, not
/// JavaScript-lazy (unlike the films grid), and each item already carries the
/// watched date, rating, like/rewatch flags, the TMDB id, AND the poster image
/// URL — so entries render art with no further enrichment. It covers the
/// member's most recent ~50 diary entries.
enum LetterboxdRSS {

    static func entries(_ xml: String, username: String) -> [DiaryEntry] {
        items(in: xml).compactMap { entry(from: $0, username: username) }
    }

    // MARK: - Item parsing

    private static func entry(from item: String, username: String) -> DiaryEntry? {
        guard let title = value(item, "letterboxd:filmTitle") else { return nil }
        let year = value(item, "letterboxd:filmYear").flatMap { Int($0) }
        let watched = value(item, "letterboxd:watchedDate").flatMap(parseDate)
        let logged = value(item, "pubDate").flatMap(parseRFCDate) ?? watched
        let rating = value(item, "letterboxd:memberRating")
            .flatMap { Double($0) }
            .flatMap { Rating(stars: $0) }
        let liked = (value(item, "letterboxd:memberLike") ?? "No") == "Yes"
        let rewatch = (value(item, "letterboxd:rewatch") ?? "No") == "Yes"
        let tmdb = value(item, "tmdb:movieId").flatMap { Int($0) }
        let link = value(item, "link") ?? ""
        let slug = filmSlug(from: link) ?? title.lowercased().replacingOccurrences(of: " ", with: "-")
        let guid = value(item, "guid") ?? "\(slug)-\(watched.map(String.init(describing:)) ?? "")"
        let description = value(item, "description") ?? ""
        let poster = posterURL(in: description)
        let review = reviewText(in: description)

        let film = Film(
            id: slug,
            name: title,
            releaseYear: year,
            tmdbID: tmdb,
            posterURL: poster
        )
        return DiaryEntry(
            id: guid,
            film: film,
            watchedDate: watched,
            loggedDate: logged,
            rating: rating,
            isRewatch: rewatch,
            isLiked: liked,
            review: review
        )
    }

    // MARK: - Extraction helpers

    private static func items(in xml: String) -> [String] {
        matches(pattern: "<item>(.*?)</item>", in: xml)
    }

    /// First captured group of `<tag ...>VALUE</tag>` (tag may carry attributes),
    /// with CDATA and basic XML entities unwrapped.
    private static func value(_ item: String, _ tag: String) -> String? {
        let escaped = NSRegularExpression.escapedPattern(for: tag)
        guard let raw = matches(pattern: "<\(escaped)(?:\\s[^>]*)?>(.*?)</\(escaped)>", in: item).first else {
            return nil
        }
        return clean(raw)
    }

    private static func filmSlug(from link: String) -> String? {
        guard let range = link.range(of: "/film/") else { return nil }
        let tail = link[range.upperBound...]
        let slug = tail.prefix { $0 != "/" }
        return slug.isEmpty ? nil : String(slug)
    }

    private static func posterURL(in description: String) -> URL? {
        guard let src = matches(pattern: "<img[^>]+src=\"([^\"]+)\"", in: description).first else { return nil }
        return URL(string: src.replacingOccurrences(of: "&amp;", with: "&"))
    }

    private static func reviewText(in description: String) -> String? {
        // The last <p> in the description that isn't the poster image.
        let paragraphs = matches(pattern: "<p>(.*?)</p>", in: description)
        let text = paragraphs
            .map { clean($0) }
            .filter { !$0.isEmpty && !$0.contains("<img") }
            .last
        return (text?.isEmpty ?? true) ? nil : text
    }

    // MARK: - Low level

    /// All first-capture-group matches for `pattern` (dot matches newlines).
    private static func matches(pattern: String, in text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            return []
        }
        let ns = text as NSString
        return regex.matches(in: text, range: NSRange(location: 0, length: ns.length)).compactMap { match in
            guard match.numberOfRanges > 1 else { return nil }
            let r = match.range(at: 1)
            return r.location == NSNotFound ? nil : ns.substring(with: r)
        }
    }

    private static func clean(_ s: String) -> String {
        var v = s
        if let cdata = matches(pattern: "<!\\[CDATA\\[(.*?)\\]\\]>", in: v).first { v = cdata }
        return v
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func parseDate(_ s: String) -> Date? {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: s)
    }

    private static func parseRFCDate(_ s: String) -> Date? {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        return f.date(from: s)
    }
}
