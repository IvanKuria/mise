import Foundation
@testable import LetterboxdKit

/// A test transport that returns canned responses in sequence, so tests never
/// touch the network. Records every request for assertions.
final class MockTransport: LetterboxdTransport, @unchecked Sendable {
    struct Response {
        let status: Int
        let data: Data
        init(status: Int = 200, data: Data) {
            self.status = status
            self.data = data
        }
    }

    private let responses: [Response]
    private var index = 0
    private(set) var recordedRequests: [URLRequest] = []
    private let lock = NSLock()

    /// Provide one response per expected call, consumed in order. The last
    /// response repeats if more calls arrive than provided.
    init(responses: [Response]) {
        precondition(!responses.isEmpty)
        self.responses = responses
    }

    convenience init(json: Data, status: Int = 200) {
        self.init(responses: [Response(status: status, data: json)])
    }

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let response = lock.withLock { () -> Response in
            recordedRequests.append(request)
            let r = responses[min(index, responses.count - 1)]
            index += 1
            return r
        }

        let http = HTTPURLResponse(
            url: request.url!,
            statusCode: response.status,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!
        return (response.data, http)
    }

    var callCount: Int {
        lock.withLock { index }
    }
}

/// A credentials provider that returns fixed values for deterministic signing.
struct FixedCredentialsProvider: RequestCredentialsProvider {
    let fixedNonce: String
    let fixedTimestamp: Int
    func nonce() -> String { fixedNonce }
    func timestamp() -> Int { fixedTimestamp }
}
