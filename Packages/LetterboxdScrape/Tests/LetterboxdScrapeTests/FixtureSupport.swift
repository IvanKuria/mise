import Foundation
@testable import LetterboxdScrape

/// Loads a trimmed HTML fixture bundled with the test target.
enum Fixture {
    static func html(_ name: String) throws -> String {
        guard let url = Bundle.module.url(forResource: name, withExtension: "html", subdirectory: "Fixtures") else {
            throw FixtureError.missing(name)
        }
        return try String(contentsOf: url, encoding: .utf8)
    }

    enum FixtureError: Error { case missing(String) }
}

/// An `HTMLFetching` that returns canned fixture HTML keyed by URL. No network.
final class MockFetcher: HTMLFetching, @unchecked Sendable {
    /// Maps an absolute URL string to fixture content.
    var responses: [String: String] = [:]
    /// Records the URLs requested, in order (for assertions on pagination/politeness).
    private(set) var requested: [URL] = []

    init(responses: [String: String] = [:]) {
        self.responses = responses
    }

    func html(for url: URL) async throws -> String {
        requested.append(url)
        if let body = responses[url.absoluteString] { return body }
        // Default: an empty page so pagination naturally terminates.
        return "<!DOCTYPE html><html><body></body></html>"
    }
}
