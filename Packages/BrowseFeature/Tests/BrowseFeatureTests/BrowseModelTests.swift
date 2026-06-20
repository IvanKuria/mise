import Testing
import Foundation
@testable import BrowseFeature
import MiseCore
import FilmQuery

@MainActor
struct BrowseModelTests {

    // MARK: - Fixtures

    private static func film(
        _ id: String,
        name: String,
        year: Int? = nil,
        runtime: Int? = nil,
        genres: [String] = []
    ) -> Film {
        Film(
            id: id,
            name: name,
            releaseYear: year,
            runtimeMinutes: runtime,
            genres: genres.map { Genre(id: $0, name: $0) }
        )
    }

    private static func entry(
        _ id: String,
        film: Film,
        date: Date? = nil,
        halfStars: Int? = nil,
        rewatch: Bool = false,
        liked: Bool = false,
        review: String? = nil
    ) -> DiaryEntry {
        DiaryEntry(
            id: id,
            film: film,
            watchedDate: date,
            rating: halfStars.flatMap { Rating(halfStars: $0) },
            isRewatch: rewatch,
            isLiked: liked,
            review: review
        )
    }

    private static let day0 = Date(timeIntervalSince1970: 1_700_000_000)
    private static func day(_ offset: Int) -> Date { day0.addingTimeInterval(Double(offset) * 86_400) }

    private static var sample: [DiaryEntry] {
        [
            entry("e1", film: film("f1", name: "Alien", year: 1979, runtime: 117, genres: ["Horror", "Sci-Fi"]),
                  date: day(0), halfStars: 9, rewatch: true, liked: true, review: "Great"),
            entry("e2", film: film("f2", name: "Heat", year: 1995, runtime: 170, genres: ["Crime"]),
                  date: day(5), halfStars: 8, liked: true),
            entry("e3", film: film("f3", name: "Drive", year: 2011, runtime: 100, genres: ["Crime", "Drama"]),
                  date: day(10), halfStars: 7),
            entry("e4", film: film("f4", name: "Solaris", year: 1972, runtime: 167, genres: ["Sci-Fi"]),
                  date: day(2), halfStars: 6, rewatch: true),
        ]
    }

    // MARK: - Defaults & facet delegation

    @Test func defaultsToAllAndWatchedDateDesc() {
        let model = BrowseModel(entries: Self.sample)
        #expect(model.filter == .all)
        #expect(model.sort == .watchedDateDesc)
        #expect(model.hasActiveFilter == false)
        #expect(model.resultCount == 4)
    }

    @Test func facetsDelegateToFilmQuery() {
        let entries = Self.sample
        let model = BrowseModel(entries: entries)
        #expect(model.facets == FilmQuery.availableFacets(in: entries))
    }

    @Test func facetsDeriveFromUnfilteredSource() {
        let model = BrowseModel(entries: Self.sample)
        model.toggleGenre("Horror") // narrows results to one entry
        #expect(model.resultCount == 1)
        // Facets still reflect the whole library, not the filtered subset.
        #expect(model.facets == FilmQuery.availableFacets(in: Self.sample))
        let genreNames = Set(model.facets.genres.map(\.value))
        #expect(genreNames == ["Horror", "Sci-Fi", "Crime", "Drama"])
    }

    // MARK: - Results delegate to FilmQuery.apply

    @Test func resultsDelegateToFilmQueryApply() {
        let entries = Self.sample
        let model = BrowseModel(entries: entries)
        model.toggleGenre("Crime")
        model.sort = .ratingDesc
        let expected = FilmQuery.apply(model.filter, sort: .ratingDesc, to: entries)
        #expect(model.results == expected)
        #expect(model.resultFilms == expected.map(\.film))
    }

    @Test func sortReordersResults() {
        let model = BrowseModel(entries: Self.sample)
        model.sort = .ratingDesc
        #expect(model.results.map(\.id) == ["e1", "e2", "e3", "e4"])
        model.sort = .ratingAsc
        #expect(model.results.map(\.id) == ["e4", "e3", "e2", "e1"])
        model.sort = .titleAsc
        #expect(model.results.map(\.film.name) == ["Alien", "Drive", "Heat", "Solaris"])
    }

    // MARK: - Rating filter

    @Test func ratingRangeFilters() {
        let model = BrowseModel(entries: Self.sample)
        model.setRatingRange(minHalfStars: 8, maxHalfStars: 10)
        #expect(model.filter.ratingRange == Rating(halfStars: 8)!...Rating(halfStars: 10)!)
        #expect(Set(model.results.map(\.id)) == ["e1", "e2"])
    }

    @Test func invalidRatingRangeIsIgnored() {
        let model = BrowseModel(entries: Self.sample)
        model.setRatingRange(minHalfStars: 9, maxHalfStars: 3) // min > max
        #expect(model.filter.ratingRange == nil)
        model.setRatingRange(minHalfStars: 0, maxHalfStars: 5) // out of range
        #expect(model.filter.ratingRange == nil)
    }

    @Test func nilRatingClearsRange() {
        let model = BrowseModel(entries: Self.sample)
        model.setRatingRange(minHalfStars: 8, maxHalfStars: 10)
        model.setRatingRange(minHalfStars: nil, maxHalfStars: nil)
        #expect(model.filter.ratingRange == nil)
    }

    // MARK: - Genre / decade toggles

    @Test func toggleGenreAddsAndRemoves() {
        let model = BrowseModel(entries: Self.sample)
        model.toggleGenre("Crime")
        #expect(model.filter.genres == ["Crime"])
        model.toggleGenre("Drama")
        #expect(model.filter.genres == ["Crime", "Drama"])
        model.toggleGenre("Crime")
        #expect(model.filter.genres == ["Drama"])
    }

    @Test func toggleDecadeFilters() {
        let model = BrowseModel(entries: Self.sample)
        model.toggleDecade(1970)
        #expect(model.filter.decades == [1970])
        #expect(Set(model.results.map(\.id)) == ["e1", "e4"]) // 1979, 1972
        model.toggleDecade(1970)
        #expect(model.filter.decades.isEmpty)
    }

    // MARK: - Runtime

    @Test func runtimeRangeFilters() {
        let model = BrowseModel(entries: Self.sample)
        model.setRuntimeRange(160...200)
        #expect(Set(model.results.map(\.id)) == ["e2", "e4"]) // 170, 167
        model.setRuntimeRange(nil)
        #expect(model.filter.runtimeRange == nil)
        #expect(model.resultCount == 4)
    }

    // MARK: - Tri-state flag cycling

    @Test func cycleRewatchTriState() {
        let model = BrowseModel(entries: Self.sample)
        #expect(model.filter.isRewatch == nil)
        model.cycleRewatch()
        #expect(model.filter.isRewatch == true)
        #expect(Set(model.results.map(\.id)) == ["e1", "e4"])
        model.cycleRewatch()
        #expect(model.filter.isRewatch == false)
        #expect(Set(model.results.map(\.id)) == ["e2", "e3"])
        model.cycleRewatch()
        #expect(model.filter.isRewatch == nil)
    }

    @Test func cycleLikedAndReview() {
        let model = BrowseModel(entries: Self.sample)
        model.cycleLiked()
        #expect(model.filter.isLiked == true)
        #expect(Set(model.results.map(\.id)) == ["e1", "e2"])
        model.cycleReview()
        #expect(model.filter.hasReview == true)
        #expect(model.results.map(\.id) == ["e1"]) // only e1 has a review AND is liked
    }

    // MARK: - Free text

    @Test func searchFiltersByTitle() {
        let model = BrowseModel(entries: Self.sample)
        model.setSearch("li") // Alien only ("Solaris" has no "li")
        #expect(model.results.map(\.id) == ["e1"])
        model.setSearch("a") // Alien, Heat, Solaris (not Drive)
        #expect(Set(model.results.map(\.id)) == ["e1", "e2", "e4"])
        model.setSearch("   ") // whitespace-only -> no constraint
        #expect(model.resultCount == 4)
    }

    // MARK: - Clearing

    @Test func clearFiltersResetsAllButKeepsSort() {
        let model = BrowseModel(entries: Self.sample)
        model.toggleGenre("Crime")
        model.setRatingRange(minHalfStars: 7, maxHalfStars: 10)
        model.sort = .titleAsc
        model.clearFilters()
        #expect(model.filter == .all)
        #expect(model.sort == .titleAsc)
        #expect(model.resultCount == 4)
    }

    @Test func clearSingleDimensionViaChipKind() {
        let model = BrowseModel(entries: Self.sample)
        model.toggleGenre("Crime")
        model.toggleDecade(1970)
        model.clear(.genre("Crime"))
        #expect(model.filter.genres.isEmpty)
        #expect(model.filter.decades == [1970])
        model.clear(.decade(1970))
        #expect(model.filter.decades.isEmpty)
    }

    // MARK: - Active filter chips

    @Test func activeFilterChipsReflectState() {
        let model = BrowseModel(entries: Self.sample)
        #expect(model.activeFilterChips.isEmpty)
        model.toggleGenre("Crime")
        model.cycleLiked()
        model.setSearch("heat")
        let kinds = Set(model.activeFilterChips.map(\.kind))
        #expect(kinds.contains(.genre("Crime")))
        #expect(kinds.contains(.liked))
        #expect(kinds.contains(.freeText))
    }

    // MARK: - Updating source

    @Test func updateEntriesPreservesFilterAndSort() {
        let model = BrowseModel(entries: Self.sample)
        model.toggleGenre("Sci-Fi")
        model.sort = .titleAsc
        let more = Self.sample + [
            Self.entry("e5", film: Self.film("f5", name: "Arrival", year: 2016, genres: ["Sci-Fi"]))
        ]
        model.update(entries: more)
        #expect(model.entries.count == 5)
        #expect(model.filter.genres == ["Sci-Fi"])
        #expect(model.sort == .titleAsc)
        #expect(Set(model.results.map(\.id)) == ["e1", "e4", "e5"])
    }

    // MARK: - Empty source

    @Test func emptySourceYieldsEmptyResultsAndFacets() {
        let model = BrowseModel(entries: [])
        #expect(model.results.isEmpty)
        #expect(model.facets == .empty)
        #expect(model.resultCount == 0)
    }
}
