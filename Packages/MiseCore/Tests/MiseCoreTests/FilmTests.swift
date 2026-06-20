import Testing
import Foundation
@testable import MiseCore

@Suite("Film")
struct FilmTests {
    @Test("decade buckets the release year")
    func decade() {
        #expect(makeFilm(year: 1987).decade == 1980)
        #expect(makeFilm(year: 1990).decade == 1990)
        #expect(makeFilm(year: 1999).decade == 1990)
        #expect(makeFilm(year: 2001).decade == 2000)
    }

    @Test("decade is nil when the year is unknown")
    func decadeUnknown() {
        #expect(makeFilm(year: nil).decade == nil)
    }

    @Test("a film round-trips through Codable")
    func codableRoundTrip() throws {
        let film = makeFilm(year: 1975)
        let data = try JSONEncoder().encode(film)
        let decoded = try JSONDecoder().decode(Film.self, from: data)
        #expect(decoded == film)
    }

    private func makeFilm(year: Int?) -> Film {
        Film(
            id: "abc",
            name: "Test Film",
            releaseYear: year,
            runtimeMinutes: 100,
            genres: [Genre(id: "g1", name: "Drama")],
            directors: [Person(id: "p1", name: "A Director")]
        )
    }
}
