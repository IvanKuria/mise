import Foundation

/// An injectable HTTP transport so the client can be tested with no network.
public protocol LetterboxdTransport: Sendable {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

/// The real, `URLSession`-backed transport used in production.
public struct URLSessionLetterboxdTransport: LetterboxdTransport {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw LetterboxdError.invalidRequest("Non-HTTP response received")
        }
        return (data, http)
    }
}
