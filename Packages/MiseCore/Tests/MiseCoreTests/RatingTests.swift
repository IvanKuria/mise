import Testing
import Foundation
@testable import MiseCore

@Suite("Rating")
struct RatingTests {
    @Test("half-stars in 1...10 are accepted")
    func validHalfStars() {
        #expect(Rating(halfStars: 1)?.halfStars == 1)
        #expect(Rating(halfStars: 10)?.halfStars == 10)
        #expect(Rating(halfStars: 7)?.halfStars == 7)
    }

    @Test("half-stars outside 1...10 are rejected")
    func invalidHalfStars() {
        #expect(Rating(halfStars: 0) == nil)
        #expect(Rating(halfStars: 11) == nil)
        #expect(Rating(halfStars: -3) == nil)
    }

    @Test("stars value is half of half-stars")
    func starsConversion() {
        #expect(Rating(halfStars: 10)?.stars == 5.0)
        #expect(Rating(halfStars: 9)?.stars == 4.5)
        #expect(Rating(halfStars: 1)?.stars == 0.5)
    }

    @Test("init from a valid star value")
    func initFromStars() {
        #expect(Rating(stars: 4.5)?.halfStars == 9)
        #expect(Rating(stars: 5.0)?.halfStars == 10)
        #expect(Rating(stars: 0.5)?.halfStars == 1)
    }

    @Test("init from an invalid star value fails")
    func initFromInvalidStars() {
        #expect(Rating(stars: 4.3) == nil)   // not a half-step
        #expect(Rating(stars: 0.0) == nil)   // below range
        #expect(Rating(stars: 5.5) == nil)   // above range
    }

    @Test("star string renders full and half stars")
    func starString() {
        #expect(Rating(halfStars: 10)?.starString == "★★★★★")
        #expect(Rating(halfStars: 9)?.starString == "★★★★½")
        #expect(Rating(halfStars: 1)?.starString == "½")
        #expect(Rating(halfStars: 7)?.starString == "★★★½")
    }

    @Test("ratings are comparable by half-stars")
    func comparable() {
        #expect(Rating(halfStars: 6)! < Rating(halfStars: 9)!)
    }
}
