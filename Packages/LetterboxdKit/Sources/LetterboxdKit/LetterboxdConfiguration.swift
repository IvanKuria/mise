import Foundation

/// Static configuration for the client: credentials and base URL.
public struct LetterboxdConfiguration: Sendable {
    public let apiKey: String
    public let apiSecret: String
    public let baseURL: URL

    public init(
        apiKey: String,
        apiSecret: String,
        baseURL: URL = URL(string: "https://api.letterboxd.com/api/v0/")!
    ) {
        self.apiKey = apiKey
        self.apiSecret = apiSecret
        self.baseURL = baseURL
    }
}

/// Generates the per-request `nonce` and `timestamp`. Injectable so signing is
/// deterministic in tests.
public protocol RequestCredentialsProvider: Sendable {
    func nonce() -> String
    func timestamp() -> Int
}

/// The production provider: random UUID nonce, current wall-clock timestamp.
public struct LiveRequestCredentialsProvider: RequestCredentialsProvider {
    public init() {}
    public func nonce() -> String { UUID().uuidString }
    public func timestamp() -> Int { Int(Date().timeIntervalSince1970) }
}
