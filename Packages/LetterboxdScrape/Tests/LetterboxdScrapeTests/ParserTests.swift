import Foundation
import Testing
import MiseCore
import SwiftSoup
@testable import LetterboxdScrape

@Suite("Letterboxd HTML parsers")
struct ParserTests {

    // MARK: - Diary

    @Test("Diary parses film identity, rating, flags, and watched date")
    func diaryRows() throws {
        let entries = try LetterboxdParser.diaryEntries(Fixture.html("diary"))
        #expect(entries.count == 3)

        // First fixture row is the rated "Toy Story 5 (2026)" entry (value=7).
        let rated = try #require(entries.first)
        #expect(rated.film.id == "toy-story-5")
        #expect(rated.film.name == "Toy Story 5")
        #expect(rated.film.releaseYear == 2026)
        #expect(rated.rating == Rating(halfStars: 7))
        #expect(rated.isRewatch == false)
        #expect(rated.isLiked == false)

        // Watched date from the daydate href /…/for/2026/06/16/.
        let watched = try #require(rated.watchedDate)
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let comps = cal.dateComponents([.year, .month, .day], from: watched)
        #expect(comps.year == 2026)
        #expect(comps.month == 6)
        #expect(comps.day == 16)
    }

    @Test("Diary handles an unrated entry (no rating)")
    func diaryUnrated() throws {
        let entries = try LetterboxdParser.diaryEntries(Fixture.html("diary"))
        let unrated = try #require(entries.first { $0.rating == nil })
        #expect(unrated.rating == nil)
        #expect(!unrated.film.id.isEmpty)
    }

    @Test("Diary detects a liked entry")
    func diaryLiked() throws {
        let entries = try LetterboxdParser.diaryEntries(Fixture.html("diary"))
        #expect(entries.contains { $0.isLiked })
    }

    @Test("Empty diary yields no entries")
    func diaryEmpty() throws {
        let entries = try LetterboxdParser.diaryEntries(Fixture.html("diary_empty"))
        #expect(entries.isEmpty)
    }

    // MARK: - Films grid

    @Test("Films grid parses slug, name, year and owner rating")
    func filmsGrid() throws {
        let films = try LetterboxdParser.filmsGrid(Fixture.html("films"))
        #expect(films.count == 2)
        // One item is rated (rated-6 -> halfStars 6), one is not.
        let rated = try #require(films.first { $0.rating != nil })
        #expect(rated.rating == Rating(halfStars: 6))
        #expect(!rated.film.id.isEmpty)
        #expect(rated.film.name == "The Death of Robin Hood")
        #expect(rated.film.releaseYear == 2026)

        let unrated = try #require(films.first { $0.rating == nil })
        #expect(unrated.film.id == "dont-say-good-luck")
        #expect(unrated.film.releaseYear == 2026)
    }

    // MARK: - Watchlist

    @Test("Watchlist parses films")
    func watchlist() throws {
        let items = try LetterboxdParser.watchlist(Fixture.html("watchlist"))
        #expect(items.count == 2)
        let first = try #require(items.first)
        #expect(first.film.id == "miss-hokusai")
        #expect(first.film.name == "Miss Hokusai")
        #expect(first.film.releaseYear == 2015)
    }

    @Test("Empty watchlist yields no items")
    func watchlistEmpty() throws {
        let items = try LetterboxdParser.watchlist(Fixture.html("watchlist_empty"))
        #expect(items.isEmpty)
    }

    // MARK: - Lists

    @Test("Lists index parses name, id, and description")
    func lists() throws {
        let lists = try LetterboxdParser.lists(Fixture.html("lists"))
        #expect(lists.count == 2)
        let first = try #require(lists.first)
        #expect(first.id == "79829270")
        #expect(first.name == "2026")
        #expect(first.description?.contains("running list") == true)
    }

    // MARK: - Profile + statistics

    @Test("Profile parses display name and avatar")
    func profile() throws {
        let member = try LetterboxdParser.member(Fixture.html("profile"), username: "davidehrlich")
        #expect(member.id == "davidehrlich")
        #expect(member.username == "davidehrlich")
        #expect(member.displayName == "davidehrlich")
        let avatar = try #require(member.avatarURL)
        #expect(avatar.absoluteString.contains("ltrbxd.com"))
    }

    @Test("Profile statistics parse header counts")
    func statistics() throws {
        let stats = try LetterboxdParser.statistics(Fixture.html("profile"))
        #expect(stats.watchedFilmCount == 3397)
        #expect(stats.listCount == 73)
        #expect(stats.followingCount == 38)
        #expect(stats.followerCount == 210998)
    }

    // MARK: - Pagination

    @Test("Pagination reads the highest linked page number")
    func paginationDetected() throws {
        #expect(try LetterboxdParser.totalPages(in: Fixture.html("films")) == 48)
        #expect(try LetterboxdParser.totalPages(in: Fixture.html("watchlist")) == 3)
        #expect(try LetterboxdParser.totalPages(in: Fixture.html("diary")) == 4)
    }

    @Test("No pagination block means a single page")
    func paginationSingle() throws {
        #expect(try LetterboxdParser.totalPages(in: Fixture.html("profile")) == 1)
    }

    // MARK: - Rating class mapping

    @Test("rated-N class maps directly to Rating(halfStars: N)", arguments: 1...10)
    func ratingClassMapping(n: Int) throws {
        let html = "<span class=\"rating rated-\(n)\">x</span>"
        let span = try SwiftSoup.parse(html).select("span.rating").first()
        let rating = LetterboxdParser.ratingFromClass(span)
        #expect(rating == Rating(halfStars: n))
    }

    @Test("Missing rating span yields nil rating")
    func ratingClassMissing() {
        #expect(LetterboxdParser.ratingFromClass(nil) == nil)
    }
}
