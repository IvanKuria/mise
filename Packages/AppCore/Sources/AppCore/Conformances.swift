import FilmEnrichment
import LetterboxdScrape
import LocalStore
import TMDBKit

// MARK: - Protocol conformances
//
// These are hosted in AppCore so the underlying packages stay decoupled:
// LetterboxdScrape doesn't depend on LocalStore, and TMDBKit doesn't depend on
// FilmEnrichment. The conformances are structural — every required method already
// exists on the conforming type with the exact signature (the default arguments on
// `ScrapingFetcher.logEntries` satisfy the protocol requirement), so the bodies
// are empty.

/// `ScrapingFetcher` reads public Letterboxd data; its read methods match
/// `LetterboxdFetching` exactly. Declared `@retroactive` because both the type
/// and the protocol are imported and AppCore deliberately owns this binding to
/// keep LetterboxdScrape decoupled from LocalStore.
extension ScrapingFetcher: @retroactive LetterboxdFetching {}

/// `TMDBClient`'s `search`/`movie` methods match `MovieMetadataProviding`.
/// `@retroactive` for the same reason: TMDBKit stays decoupled from FilmEnrichment.
extension TMDBClient: @retroactive MovieMetadataProviding {}
