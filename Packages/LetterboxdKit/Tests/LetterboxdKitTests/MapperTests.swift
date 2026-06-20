import Foundation
import Testing
import MiseCore
@testable import LetterboxdKit

@Suite("Wire DTO -> MiseCore mappers")
struct MapperTests {

    private func decode<T: Decodable>(_ type: T.Type, _ data: Data) throws -> T {
        try JSONDecoder().decode(T.self, from: data)
    }

    @Test("member maps id, username, display name, and largest avatar")
    func member() throws {
        let dto = try decode(MemberSearchResponseDTO.self, Fixtures.memberSearch)
        let m = LetterboxdMappers.member(dto.items!.first!.member!)
        #expect(m?.id == "MEM123")
        #expect(m?.username == "dave")
        #expect(m?.displayName == "Dave Letterboxd")
        #expect(m?.avatarURL?.absoluteString == "https://a.ltrbxd.com/large.jpg")
    }

    @Test("statistics maps counts and converts star ratings to half-star histogram")
    func statistics() throws {
        let dto = try decode(MemberStatisticsDTO.self, Fixtures.statistics)
        let s = LetterboxdMappers.statistics(dto)
        #expect(s.watchedFilmCount == 2500)
        #expect(s.diaryEntryCount == 1800)
        #expect(s.listCount == 12)
        #expect(s.followerCount == 340)
        #expect(s.followingCount == 120)
        // 0.5 stars -> 1 half-star; 3.0 -> 6; 4.5 -> 9; 5.0 -> 10
        #expect(s.ratingsHistogram[1] == 3)
        #expect(s.ratingsHistogram[6] == 200)
        #expect(s.ratingsHistogram[9] == 90)
        #expect(s.ratingsHistogram[10] == 45)
    }

    @Test("film maps all fields including tmdb id from links and best poster")
    func film() throws {
        let dto = try decode(FilmDTO.self, Fixtures.film)
        let f = LetterboxdMappers.film(dto)!
        #expect(f.id == "2bbs")
        #expect(f.name == "Parasite")
        #expect(f.releaseYear == 2019)
        #expect(f.runtimeMinutes == 133)
        #expect(f.genres.map(\.name) == ["Comedy", "Thriller"])
        #expect(f.directors.map(\.name) == ["Bong Joon-ho"])
        #expect(f.cast.first?.name == "Song Kang-ho")
        #expect(f.cast.first?.characterName == "Ki-taek")
        #expect(f.countries == ["South Korea"])
        #expect(f.languages == ["Korean"])
        #expect(f.tmdbID == 496243)
        #expect(f.posterURL?.absoluteString == "https://a.ltrbxd.com/poster.jpg")
        #expect(f.letterboxdAverageRating == 4.56)
        #expect(f.letterboxdURL?.absoluteString == "https://letterboxd.com/film/parasite-2019/")
        #expect(f.decade == 2010)
    }

    @Test("film with no id does not map")
    func filmNoID() {
        let dto = FilmDTO(
            id: nil, name: "x", releaseYear: nil, runTime: nil, genres: nil,
            contributions: nil, countries: nil, languages: nil, poster: nil,
            rating: nil, links: nil
        )
        #expect(LetterboxdMappers.film(dto) == nil)
    }

    @Test("log entries map rating, rewatch, like, review, tags, and dates")
    func logEntries() throws {
        let dto = try decode(LogEntriesResponseDTO.self, Fixtures.logEntries)
        let entries = (dto.items ?? []).compactMap(LetterboxdMappers.diaryEntry)
        #expect(entries.count == 2)

        let first = entries[0]
        #expect(first.id == "LE1")
        #expect(first.film.name == "Parasite")
        #expect(first.rating == Rating(stars: 4.5))
        #expect(first.isRewatch == true)
        #expect(first.isLiked == true)
        #expect(first.review == "Still incredible.")
        #expect(first.tags == ["rewatch"])
        #expect(first.hasReview == true)
        #expect(first.watchedDate != nil)
        #expect(first.loggedDate != nil)

        let second = entries[1]
        #expect(second.rating == nil)
        #expect(second.isLiked == false)
        #expect(second.hasReview == false)
    }

    @Test("watchlist items map films")
    func watchlist() throws {
        let dto = try decode(WatchlistResponseDTO.self, Fixtures.watchlist)
        let items = (dto.items ?? []).compactMap(LetterboxdMappers.watchlistItem)
        #expect(items.count == 2)
        #expect(items.first?.film.name == "Aftersun")
        #expect(items.first?.id == "w1")
    }

    @Test("lists map name, ranked flag, and entries")
    func lists() throws {
        let dto = try decode(ListsResponseDTO.self, Fixtures.lists)
        let lists = (dto.items ?? []).compactMap(LetterboxdMappers.filmList)
        #expect(lists.count == 1)
        let list = lists[0]
        #expect(list.name == "Best of 2019")
        #expect(list.ranked == true)
        #expect(list.description == "My favourites")
        #expect(list.films.map(\.name) == ["Parasite", "Marriage Story"])
    }

    @Test("date parsing tolerates yyyy-MM-dd and ISO8601 timestamps")
    func dateParsing() {
        #expect(LetterboxdMappers.parseDate("2024-03-15") != nil)
        #expect(LetterboxdMappers.parseDate("2024-03-15T20:30:00Z") != nil)
        #expect(LetterboxdMappers.parseDate("2024-03-15T20:30:00.123Z") != nil)
        #expect(LetterboxdMappers.parseDate("") == nil)
        #expect(LetterboxdMappers.parseDate(nil) == nil)
    }
}
