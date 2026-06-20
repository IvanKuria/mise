import Foundation

/// Streaming availability passed in as data, keeping this package independent of
/// any streaming API. Maps a film id to the set of service names the user can
/// watch it on (e.g. `["Netflix", "Max"]`).
public struct StreamingAvailability: Hashable, Sendable {
    /// filmID -> service names.
    public let byFilmID: [String: Set<String>]

    public init(byFilmID: [String: Set<String>] = [:]) {
        self.byFilmID = byFilmID
    }

    /// The services a given film is available on, or an empty set if unknown.
    public func services(for filmID: String) -> Set<String> {
        byFilmID[filmID] ?? []
    }
}
