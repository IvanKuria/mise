import Foundation
import MiseCore

/// A built-in sample library so the app (and design iteration) can render loaded
/// screens instantly without scraping — triggered by the handle "demo".
enum SampleData {
    static func history() -> WatchHistory {
        let member = MemberSummary(
            id: "demo", username: "demo", displayName: "Demo Cinephile", avatarURL: nil
        )
        return WatchHistory(
            member: member,
            diary: diary(),
            watchlist: watchlist(),
            lists: lists(),
            statistics: nil
        )
    }

    private static func genre(_ n: String) -> Genre { Genre(id: n.lowercased(), name: n) }
    private static func person(_ n: String) -> Person { Person(id: n.lowercased().replacingOccurrences(of: " ", with: "-"), name: n) }

    private static func film(
        _ id: String, _ name: String, _ year: Int, _ runtime: Int,
        _ genres: [String], _ director: String, _ avg: Double
    ) -> Film {
        Film(
            id: id, name: name, releaseYear: year, runtimeMinutes: runtime,
            genres: genres.map(genre), directors: [person(director)],
            tmdbID: nil, posterURL: nil, letterboxdAverageRating: avg
        )
    }

    private static func day(_ daysAgo: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
    }

    private static func entry(
        _ film: Film, _ daysAgo: Int, halfStars: Int, liked: Bool = false,
        rewatch: Bool = false, review: String? = nil
    ) -> DiaryEntry {
        DiaryEntry(
            id: "d-\(film.id)-\(daysAgo)", film: film,
            watchedDate: day(daysAgo), loggedDate: day(daysAgo),
            rating: Rating(halfStars: halfStars), isRewatch: rewatch, isLiked: liked,
            review: review, tags: []
        )
    }

    private static func diary() -> [DiaryEntry] {
        [
            entry(film("parasite", "Parasite", 2019, 132, ["Thriller", "Drama"], "Bong Joon-ho", 4.5), 3, halfStars: 10, liked: true, review: "Still perfect."),
            entry(film("pcb", "Perfect Blue", 1997, 81, ["Animation", "Thriller"], "Satoshi Kon", 4.2), 6, halfStars: 9, liked: true),
            entry(film("in-the-mood", "In the Mood for Love", 2000, 98, ["Romance", "Drama"], "Wong Kar-wai", 4.4), 9, halfStars: 10, liked: true),
            entry(film("mad-max", "Mad Max: Fury Road", 2015, 120, ["Action", "Adventure"], "George Miller", 4.1), 12, halfStars: 9),
            entry(film("paddington2", "Paddington 2", 2017, 103, ["Comedy", "Family"], "Paul King", 4.3), 14, halfStars: 8, liked: true),
            entry(film("zodiac", "Zodiac", 2007, 157, ["Thriller", "Crime"], "David Fincher", 4.2), 18, halfStars: 9),
            entry(film("alien", "Alien", 1979, 117, ["Horror", "Science Fiction"], "Ridley Scott", 4.3), 23, halfStars: 9, rewatch: true),
            entry(film("akira", "Akira", 1988, 124, ["Animation", "Science Fiction"], "Katsuhiro Otomo", 4.1), 28, halfStars: 8),
            entry(film("la-haine", "La Haine", 1995, 98, ["Drama", "Crime"], "Mathieu Kassovitz", 4.2), 31, halfStars: 9),
            entry(film("whiplash", "Whiplash", 2014, 106, ["Drama", "Music"], "Damien Chazelle", 4.3), 37, halfStars: 9, liked: true),
            entry(film("the-thing", "The Thing", 1982, 109, ["Horror", "Science Fiction"], "John Carpenter", 4.2), 44, halfStars: 10, liked: true),
            entry(film("portrait", "Portrait of a Lady on Fire", 2019, 122, ["Romance", "Drama"], "Céline Sciamma", 4.3), 51, halfStars: 9, liked: true),
            entry(film("seven-samurai", "Seven Samurai", 1954, 207, ["Action", "Drama"], "Akira Kurosawa", 4.5), 58, halfStars: 10),
            entry(film("nope", "Nope", 2022, 130, ["Horror", "Science Fiction"], "Jordan Peele", 3.8), 66, halfStars: 7),
            entry(film("amelie", "Amélie", 2001, 122, ["Romance", "Comedy"], "Jean-Pierre Jeunet", 4.1), 73, halfStars: 8),
            entry(film("blade-runner", "Blade Runner 2049", 2017, 164, ["Science Fiction", "Drama"], "Denis Villeneuve", 4.2), 88, halfStars: 9, liked: true),
            entry(film("spirited", "Spirited Away", 2001, 125, ["Animation", "Fantasy"], "Hayao Miyazaki", 4.5), 95, halfStars: 10, rewatch: true),
            entry(film("burning", "Burning", 2018, 148, ["Drama", "Mystery"], "Lee Chang-dong", 4.0), 110, halfStars: 8),
        ]
    }

    private static func watchlist() -> [WatchlistItem] {
        [
            WatchlistItem(film: film("stalker", "Stalker", 1979, 162, ["Science Fiction", "Drama"], "Andrei Tarkovsky", 4.3)),
            WatchlistItem(film: film("come-and-see", "Come and See", 1985, 142, ["War", "Drama"], "Elem Klimov", 4.4)),
            WatchlistItem(film: film("tokyo-story", "Tokyo Story", 1953, 137, ["Drama"], "Yasujirō Ozu", 4.4)),
            WatchlistItem(film: film("ha", "Happy as Lazzaro", 2018, 127, ["Drama"], "Alice Rohrwacher", 4.0)),
            WatchlistItem(film: film("drive-my-car", "Drive My Car", 2021, 179, ["Drama"], "Ryūsuke Hamaguchi", 4.1)),
        ]
    }

    private static func lists() -> [FilmList] {
        [
            FilmList(id: "fav", name: "All-Time Favorites", description: "The ones I'd save from a fire.", ranked: true, films: [
                film("parasite", "Parasite", 2019, 132, ["Thriller", "Drama"], "Bong Joon-ho", 4.5),
                film("the-thing", "The Thing", 1982, 109, ["Horror", "Science Fiction"], "John Carpenter", 4.2),
                film("spirited", "Spirited Away", 2001, 125, ["Animation", "Fantasy"], "Hayao Miyazaki", 4.5),
            ]),
        ]
    }
}
