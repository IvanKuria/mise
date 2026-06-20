import Foundation

/// Fetches raw HTML for a URL. Injectable so parsers can be tested against saved
/// fixtures with no live network.
public protocol HTMLFetching: Sendable {
    func html(for url: URL) async throws -> String
}

/// Politeness configuration for the live fetcher: a real browser User-Agent and a
/// minimum delay enforced between consecutive requests.
public struct PolitenessConfig: Sendable {
    /// Sent as the `User-Agent` header. Defaults to a real Safari UA (verified to
    /// return HTTP 200 from Letterboxd, where a default URLSession UA is blocked).
    public var userAgent: String
    /// Minimum time between the start of consecutive requests.
    public var minRequestInterval: Duration

    public init(
        userAgent: String = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15",
        minRequestInterval: Duration = .milliseconds(500)
    ) {
        self.userAgent = userAgent
        self.minRequestInterval = minRequestInterval
    }
}

/// Errors thrown while fetching pages.
public enum ScrapeError: Error, Equatable, Sendable {
    /// Non-2xx HTTP status (e.g. 403 from a Cloudflare challenge, 404 for an
    /// unknown handle).
    case httpStatus(Int, url: URL)
    /// The response body was not decodable as UTF-8 text.
    case notText(url: URL)
}

/// A real `HTMLFetching` over `URLSession` that sets a browser User-Agent and
/// enforces the configured politeness delay between requests.
public actor URLSessionHTMLFetcher: HTMLFetching {
    private let session: URLSession
    private let config: PolitenessConfig
    /// Wall-clock instant of the last request start, to space requests out.
    private var lastRequestStart: ContinuousClock.Instant?
    private let clock = ContinuousClock()

    public init(config: PolitenessConfig = PolitenessConfig(), session: URLSession = .shared) {
        self.config = config
        self.session = session
    }

    public func html(for url: URL) async throws -> String {
        try await throttle()

        var request = URLRequest(url: url)
        request.setValue(config.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue(
            "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            forHTTPHeaderField: "Accept"
        )
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")

        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw ScrapeError.httpStatus(http.statusCode, url: url)
        }
        guard let text = String(data: data, encoding: .utf8) else {
            throw ScrapeError.notText(url: url)
        }
        return text
    }

    /// Sleep just long enough that requests are spaced by `minRequestInterval`.
    private func throttle() async throws {
        let now = clock.now
        if let last = lastRequestStart {
            let elapsed = last.duration(to: now)
            if elapsed < config.minRequestInterval {
                try await clock.sleep(for: config.minRequestInterval - elapsed)
            }
        }
        lastRequestStart = clock.now
    }
}
