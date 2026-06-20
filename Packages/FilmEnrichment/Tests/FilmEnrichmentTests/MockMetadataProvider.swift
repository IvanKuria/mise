import Foundation
import TMDBKit
@testable import FilmEnrichment

/// An in-memory ``MovieMetadataProviding`` for tests. Records calls so we can
/// assert on search/movie behavior and caching, never touching the network.
actor MockMetadataProvider: MovieMetadataProviding {
    /// Canned search results keyed by lowercased title.
    var searchResults: [String: [TMDBSearchResult]]
    /// Canned movies keyed by tmdb id.
    var movies: [Int: TMDBMovie]

    private(set) var searchCalls: [(title: String, year: Int?)] = []
    private(set) var movieCalls: [Int] = []

    init(
        searchResults: [String: [TMDBSearchResult]] = [:],
        movies: [Int: TMDBMovie] = [:]
    ) {
        self.searchResults = searchResults
        self.movies = movies
    }

    func search(title: String, year: Int?) async throws -> [TMDBSearchResult] {
        searchCalls.append((title, year))
        return searchResults[title.lowercased()] ?? []
    }

    func movie(tmdbID: Int) async throws -> TMDBMovie {
        movieCalls.append(tmdbID)
        guard let movie = movies[tmdbID] else {
            throw TMDBError.invalidResponse
        }
        return movie
    }

    var searchCallCount: Int { searchCalls.count }
    var movieCallCount: Int { movieCalls.count }
}
