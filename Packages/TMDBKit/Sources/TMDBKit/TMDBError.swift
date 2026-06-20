import Foundation

/// Errors surfaced by ``TMDBClient`` and its transport.
public enum TMDBError: Error, Sendable {
    /// The server returned a non-2xx HTTP status. `data` is the raw response body, if any.
    case httpStatus(code: Int, data: Data)
    /// The response body could not be decoded into the expected shape.
    case decoding(any Error)
    /// A response was received that was not an `HTTPURLResponse`.
    case invalidResponse
}
