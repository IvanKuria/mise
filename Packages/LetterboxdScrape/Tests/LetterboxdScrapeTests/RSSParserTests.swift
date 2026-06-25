import Foundation
import Testing
import MiseCore
@testable import LetterboxdScrape

@Suite("Letterboxd RSS parser")
struct RSSParserTests {

    // MARK: - Fixtures

    /// A single, fully-populated diary item modeled on a real Letterboxd RSS feed.
    static let soundOfMetalItem = """
    <item>
      <title>Sound of Metal, 2019 - ★★★★½</title>
      <link>https://letterboxd.com/davidehrlich/film/sound-of-metal/</link>
      <guid isPermaLink="false">letterboxd-watch-123456789</guid>
      <pubDate>Mon, 13 Apr 2026 12:00:00 +0000</pubDate>
      <letterboxd:watchedDate>2026-04-13</letterboxd:watchedDate>
      <letterboxd:rewatch>No</letterboxd:rewatch>
      <letterboxd:filmTitle>Sound of Metal</letterboxd:filmTitle>
      <letterboxd:filmYear>2019</letterboxd:filmYear>
      <letterboxd:memberRating>4.5</letterboxd:memberRating>
      <letterboxd:memberLike>Yes</letterboxd:memberLike>
      <tmdb:movieId>502033</tmdb:movieId>
      <description><![CDATA[ <p><img src="https://a.ltrbxd.com/resized/film-poster/5/0/2/0/3/3/502033-sound-of-metal-0-230-0-345-crop.jpg?v=abc"/></p> <p>great film</p> ]]></description>
    </item>
    """

    /// Wraps one or more `<item>` blocks in a minimal RSS channel envelope.
    static func feed(_ items: String...) -> String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <rss xmlns:letterboxd="https://letterboxd.com" xmlns:tmdb="https://themoviedb.org" version="2.0">
          <channel>
            <title>davidehrlich's films</title>
            <link>https://letterboxd.com/davidehrlich/</link>
            \(items.joined(separator: "\n"))
          </channel>
        </rss>
        """
    }

    private func utcComponents(_ date: Date) -> DateComponents {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal.dateComponents([.year, .month, .day], from: date)
    }

    // MARK: - Fully-populated item

    @Test("Parses film identity, slug, rating, flags, tmdb, poster, and review")
    func fullyPopulatedItem() throws {
        let entries = LetterboxdRSS.entries(Self.feed(Self.soundOfMetalItem), username: "davidehrlich")
        #expect(entries.count == 1)

        let entry = try #require(entries.first)

        // Film identity. Year comes from <letterboxd:filmYear>, not the title.
        #expect(entry.film.name == "Sound of Metal")
        #expect(entry.film.releaseYear == 2019)
        // Slug id extracted from /film/<slug>/.
        #expect(entry.film.id == "sound-of-metal")

        // TMDB id.
        #expect(entry.film.tmdbID == 502033)

        // Poster URL is the <img src> from the description.
        let poster = try #require(entry.film.posterURL)
        #expect(poster.absoluteString == "https://a.ltrbxd.com/resized/film-poster/5/0/2/0/3/3/502033-sound-of-metal-0-230-0-345-crop.jpg?v=abc")

        // Rating: 4.5 stars.
        let rating = try #require(entry.rating)
        #expect(rating.stars == 4.5)
        #expect(rating == Rating(stars: 4.5))

        // Flags.
        #expect(entry.isLiked == true)
        #expect(entry.isRewatch == false)

        // Review text is the prose paragraph, not the poster image markup.
        #expect(entry.review == "great film")
    }

    @Test("Watched date parses as yyyy-MM-dd in UTC")
    func watchedDate() throws {
        let entries = LetterboxdRSS.entries(Self.feed(Self.soundOfMetalItem), username: "davidehrlich")
        let entry = try #require(entries.first)
        let watched = try #require(entry.watchedDate)
        let comps = utcComponents(watched)
        #expect(comps.year == 2026)
        #expect(comps.month == 4)
        #expect(comps.day == 13)
    }

    // MARK: - Edge cases

    @Test("Item with no rating yields nil rating")
    func noRating() throws {
        let item = """
        <item>
          <title>Some Film, 2020</title>
          <link>https://letterboxd.com/davidehrlich/film/some-film/</link>
          <letterboxd:watchedDate>2026-01-02</letterboxd:watchedDate>
          <letterboxd:rewatch>No</letterboxd:rewatch>
          <letterboxd:filmTitle>Some Film</letterboxd:filmTitle>
          <letterboxd:filmYear>2020</letterboxd:filmYear>
          <letterboxd:memberLike>No</letterboxd:memberLike>
          <tmdb:movieId>111</tmdb:movieId>
          <description><![CDATA[ <p>no stars here</p> ]]></description>
        </item>
        """
        let entries = LetterboxdRSS.entries(Self.feed(item), username: "davidehrlich")
        let entry = try #require(entries.first)
        #expect(entry.rating == nil)
        #expect(entry.isLiked == false)
        #expect(entry.film.name == "Some Film")
    }

    @Test("Item with no poster image yields nil posterURL")
    func noPoster() throws {
        let item = """
        <item>
          <title>No Art, 2021 - ★★★</title>
          <link>https://letterboxd.com/davidehrlich/film/no-art/</link>
          <letterboxd:watchedDate>2026-02-03</letterboxd:watchedDate>
          <letterboxd:rewatch>No</letterboxd:rewatch>
          <letterboxd:filmTitle>No Art</letterboxd:filmTitle>
          <letterboxd:filmYear>2021</letterboxd:filmYear>
          <letterboxd:memberRating>3.0</letterboxd:memberRating>
          <letterboxd:memberLike>No</letterboxd:memberLike>
          <tmdb:movieId>222</tmdb:movieId>
          <description><![CDATA[ <p>just words, no image</p> ]]></description>
        </item>
        """
        let entries = LetterboxdRSS.entries(Self.feed(item), username: "davidehrlich")
        let entry = try #require(entries.first)
        #expect(entry.film.posterURL == nil)
        #expect(entry.review == "just words, no image")
        #expect(entry.rating?.stars == 3.0)
    }

    @Test("HTML entities (&amp;) in the poster URL are decoded")
    func encodedPosterURL() throws {
        let item = """
        <item>
          <title>Encoded, 2022 - ★★★★</title>
          <link>https://letterboxd.com/davidehrlich/film/encoded/</link>
          <letterboxd:watchedDate>2026-03-04</letterboxd:watchedDate>
          <letterboxd:rewatch>No</letterboxd:rewatch>
          <letterboxd:filmTitle>Encoded</letterboxd:filmTitle>
          <letterboxd:filmYear>2022</letterboxd:filmYear>
          <letterboxd:memberRating>4.0</letterboxd:memberRating>
          <letterboxd:memberLike>No</letterboxd:memberLike>
          <tmdb:movieId>333</tmdb:movieId>
          <description><![CDATA[ <p><img src="https://a.ltrbxd.com/poster.jpg?v=abc&amp;size=large"/></p> <p>nice</p> ]]></description>
        </item>
        """
        let entries = LetterboxdRSS.entries(Self.feed(item), username: "davidehrlich")
        let entry = try #require(entries.first)
        let poster = try #require(entry.film.posterURL)
        #expect(poster.absoluteString == "https://a.ltrbxd.com/poster.jpg?v=abc&size=large")
    }

    @Test("Multiple items preserve feed order")
    func multipleItemsOrderPreserved() throws {
        let first = """
        <item>
          <link>https://letterboxd.com/davidehrlich/film/first-film/</link>
          <letterboxd:filmTitle>First Film</letterboxd:filmTitle>
          <letterboxd:filmYear>2001</letterboxd:filmYear>
          <letterboxd:watchedDate>2026-01-01</letterboxd:watchedDate>
        </item>
        """
        let second = """
        <item>
          <link>https://letterboxd.com/davidehrlich/film/second-film/</link>
          <letterboxd:filmTitle>Second Film</letterboxd:filmTitle>
          <letterboxd:filmYear>2002</letterboxd:filmYear>
          <letterboxd:watchedDate>2026-01-02</letterboxd:watchedDate>
        </item>
        """
        let third = """
        <item>
          <link>https://letterboxd.com/davidehrlich/film/third-film/</link>
          <letterboxd:filmTitle>Third Film</letterboxd:filmTitle>
          <letterboxd:filmYear>2003</letterboxd:filmYear>
          <letterboxd:watchedDate>2026-01-03</letterboxd:watchedDate>
        </item>
        """
        let entries = LetterboxdRSS.entries(Self.feed(first, second, third), username: "davidehrlich")
        #expect(entries.count == 3)
        #expect(entries.map(\.film.id) == ["first-film", "second-film", "third-film"])
        #expect(entries.map(\.film.name) == ["First Film", "Second Film", "Third Film"])
    }

    @Test("Empty feed returns no entries")
    func emptyFeed() {
        let entries = LetterboxdRSS.entries(Self.feed(), username: "davidehrlich")
        #expect(entries.isEmpty)
    }

    @Test("Item with no filmTitle is skipped")
    func itemWithoutTitleSkipped() {
        let item = """
        <item>
          <link>https://letterboxd.com/davidehrlich/film/ghost/</link>
          <letterboxd:filmYear>2024</letterboxd:filmYear>
        </item>
        """
        let entries = LetterboxdRSS.entries(Self.feed(item), username: "davidehrlich")
        #expect(entries.isEmpty)
    }

    @Test("Rewatch=Yes is detected")
    func rewatchDetected() throws {
        let item = """
        <item>
          <link>https://letterboxd.com/davidehrlich/film/rewatched/</link>
          <letterboxd:filmTitle>Rewatched</letterboxd:filmTitle>
          <letterboxd:filmYear>2010</letterboxd:filmYear>
          <letterboxd:watchedDate>2026-05-05</letterboxd:watchedDate>
          <letterboxd:rewatch>Yes</letterboxd:rewatch>
        </item>
        """
        let entries = LetterboxdRSS.entries(Self.feed(item), username: "davidehrlich")
        let entry = try #require(entries.first)
        #expect(entry.isRewatch == true)
    }
}

@Suite("Letterboxd URLs")
struct LetterboxdURLsTests {

    @Test("rss builds the member RSS feed path")
    func rss() {
        #expect(LetterboxdURLs.rss("davidehrlich").absoluteString == "https://letterboxd.com/davidehrlich/rss/")
    }

    @Test("diary builds the canonical diary path and paginates")
    func diary() {
        #expect(LetterboxdURLs.diary("davidehrlich").absoluteString == "https://letterboxd.com/davidehrlich/diary/")
        #expect(LetterboxdURLs.diary("davidehrlich", page: 1).absoluteString == "https://letterboxd.com/davidehrlich/diary/")
        #expect(LetterboxdURLs.diary("davidehrlich", page: 3).absoluteString == "https://letterboxd.com/davidehrlich/diary/page/3/")
    }

    @Test("films builds the films grid path and paginates")
    func films() {
        #expect(LetterboxdURLs.films("davidehrlich").absoluteString == "https://letterboxd.com/davidehrlich/films/")
        #expect(LetterboxdURLs.films("davidehrlich", page: 2).absoluteString == "https://letterboxd.com/davidehrlich/films/page/2/")
    }

    @Test("profile builds the member profile path")
    func profile() {
        #expect(LetterboxdURLs.profile("davidehrlich").absoluteString == "https://letterboxd.com/davidehrlich/")
    }
}
