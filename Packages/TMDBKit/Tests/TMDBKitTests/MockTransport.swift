import Foundation
@testable import TMDBKit

/// A test transport that records the request and returns a canned response,
/// so tests never touch the network.
final class MockTransport: TMDBTransport, @unchecked Sendable {
    enum Outcome {
        case success(Data)
        case status(Int, Data)
        case failure(Error)
    }

    private let outcome: Outcome
    private(set) var recordedRequests: [URLRequest] = []

    init(_ outcome: Outcome) {
        self.outcome = outcome
    }

    func data(for request: URLRequest) async throws -> Data {
        recordedRequests.append(request)
        switch outcome {
        case .success(let data):
            return data
        case .status(let code, let data):
            throw TMDBError.httpStatus(code: code, data: data)
        case .failure(let error):
            throw error
        }
    }
}
