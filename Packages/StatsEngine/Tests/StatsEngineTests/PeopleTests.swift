import Foundation
import Testing
import MiseCore
@testable import StatsEngine

@Suite("People")
struct PeopleTests {
    @Test("directors: default min count 1, sorted by count then average")
    func directors() {
        let nolan = Fixtures.person("Christopher Nolan")
        let pta = Fixtures.person("Paul Thomas Anderson")
        let f1 = Fixtures.film(id: "f1", directors: [nolan])
        let f2 = Fixtures.film(id: "f2", directors: [nolan])
        let f3 = Fixtures.film(id: "f3", directors: [pta])
        let history = Fixtures.history([
            Fixtures.entry(id: "1", film: f1, rating: Fixtures.rating(4.0)),
            Fixtures.entry(id: "2", film: f2, rating: Fixtures.rating(5.0)),
            Fixtures.entry(id: "3", film: f3, rating: Fixtures.rating(5.0)),
        ])
        let stats = StatsEngine.compute(history)
        #expect(stats.topDirectors.count == 2)
        #expect(stats.topDirectors[0].name == "Christopher Nolan") // count 2 first
        #expect(stats.topDirectors[0].count == 2)
        #expect(stats.topDirectors[0].averageRating == 4.5)
        #expect(stats.topDirectors[1].name == "Paul Thomas Anderson")
    }

    @Test("cast: default min count 2 excludes single appearances")
    func castThreshold() {
        let star = Fixtures.person("Frequent Star")
        let extra = Fixtures.person("One Timer")
        let f1 = Fixtures.film(id: "f1", cast: [star, extra])
        let f2 = Fixtures.film(id: "f2", cast: [star])
        let history = Fixtures.history([
            Fixtures.entry(id: "1", film: f1, rating: Fixtures.rating(3.0)),
            Fixtures.entry(id: "2", film: f2, rating: Fixtures.rating(4.0)),
        ])
        let stats = StatsEngine.compute(history)
        #expect(stats.topCast.count == 1)
        #expect(stats.topCast[0].name == "Frequent Star")
        #expect(stats.topCast[0].count == 2)
        #expect(stats.topCast[0].averageRating == 3.5)
    }

    @Test("ties on count broken by averageRating descending then name")
    func tieBreak() {
        let a = Fixtures.person("Alice")
        let b = Fixtures.person("Bob")
        let c = Fixtures.person("Carol")
        let fa = Fixtures.film(id: "fa", directors: [a])
        let fb = Fixtures.film(id: "fb", directors: [b])
        let fc = Fixtures.film(id: "fc", directors: [c])
        let history = Fixtures.history([
            Fixtures.entry(id: "1", film: fa, rating: Fixtures.rating(3.0)),
            Fixtures.entry(id: "2", film: fb, rating: Fixtures.rating(5.0)),
            Fixtures.entry(id: "3", film: fc, rating: Fixtures.rating(4.0)),
        ])
        let stats = StatsEngine.compute(history)
        // all count 1; order by average desc: Bob(5), Carol(4), Alice(3)
        #expect(stats.topDirectors.map(\.name) == ["Bob", "Carol", "Alice"])
    }

    @Test("custom thresholds via options")
    func customThreshold() {
        let nolan = Fixtures.person("Christopher Nolan")
        let f1 = Fixtures.film(id: "f1", directors: [nolan])
        let history = Fixtures.history([
            Fixtures.entry(id: "1", film: f1, rating: Fixtures.rating(4.0)),
        ])
        let stats = StatsEngine.compute(history, options: StatsOptions(minDirectorCount: 2))
        #expect(stats.topDirectors.isEmpty)
    }
}
