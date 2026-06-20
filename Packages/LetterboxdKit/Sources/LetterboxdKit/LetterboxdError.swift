import Foundation

/// Errors surfaced by `LetterboxdClient`.
public enum LetterboxdError: Error, Equatable, Sendable {
    /// A request could not be constructed (bad URL components, etc.).
    case invalidRequest(String)
    /// The server returned a non-success HTTP status that we did not (or could
    /// not) recover from. `body` is the raw response body for diagnostics.
    case httpStatus(code: Int, body: Data)
    /// The OAuth token endpoint did not return a usable access token.
    case authenticationFailed(String)
    /// The response body could not be decoded into the expected shape.
    case decoding(String)
    /// A handle could not be resolved to a member.
    case memberNotFound(String)
    /// Exhausted retries against transient failures (429 / 5xx).
    case retriesExhausted(lastStatus: Int)
}
