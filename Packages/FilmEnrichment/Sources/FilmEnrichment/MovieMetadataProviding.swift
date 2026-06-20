import TMDBKit

/// The TMDB calls ``FilmEnricher`` needs, abstracted so it can be tested without
/// the network. `TMDBKit.TMDBClient` conforms structurally — its `search` and
/// `movie` methods already match these signatures — so the app can declare
/// `extension TMDBClient: MovieMetadataProviding {}` with an empty body.
public protocol MovieMetadataProviding: Sendable {
    func search(title: String, year: Int?) async throws -> [TMDBSearchResult]
    func movie(tmdbID: Int) async throws -> TMDBMovie
}
