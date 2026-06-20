import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Abstraction over the network layer so the client can be tested without real requests.
///
/// Conformers are responsible for surfacing non-2xx responses as
/// ``TMDBError/httpStatus(code:data:)`` so the client can treat the returned
/// `Data` as a successful body.
public protocol TMDBTransport: Sendable {
    func data(for request: URLRequest) async throws -> Data
}

/// Production transport backed by `URLSession`.
public struct URLSessionTMDBTransport: TMDBTransport {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func data(for request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw TMDBError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw TMDBError.httpStatus(code: http.statusCode, data: data)
        }
        return data
    }
}
