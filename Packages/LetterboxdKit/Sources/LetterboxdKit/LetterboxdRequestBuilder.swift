import Foundation

/// Builds signed `URLRequest`s for the Letterboxd API.
///
/// Each request carries the query params `apikey`, `nonce`, `timestamp`, and a
/// `signature` (computed by `RequestSigner` over the fully-assembled URL). This
/// type is `struct` and pure so URL/query/signature assembly is unit-testable.
struct LetterboxdRequestBuilder: Sendable {
    let configuration: LetterboxdConfiguration
    let signer: RequestSigner
    let credentials: RequestCredentialsProvider

    init(configuration: LetterboxdConfiguration, credentials: RequestCredentialsProvider) {
        self.configuration = configuration
        self.signer = RequestSigner(sharedSecret: configuration.apiSecret)
        self.credentials = credentials
    }

    /// Build a signed request.
    /// - Parameters:
    ///   - method: HTTP method (e.g. "GET", "POST").
    ///   - path: path relative to the base URL (e.g. "member/abc/statistics").
    ///   - queryItems: endpoint-specific query items (paging, filters, etc.).
    ///   - body: optional request body (form-encoded string for the token call).
    ///   - contentType: optional `Content-Type` header for the body.
    func makeRequest(
        method: String,
        path: String,
        queryItems: [URLQueryItem] = [],
        body: String? = nil,
        contentType: String? = nil
    ) throws -> URLRequest {
        guard let resolved = URL(string: path, relativeTo: configuration.baseURL),
              var components = URLComponents(url: resolved, resolvingAgainstBaseURL: true)
        else {
            throw LetterboxdError.invalidRequest("Could not form URL for path: \(path)")
        }

        // Endpoint query items first, then the signing params, so the signed URL
        // contains the complete query string.
        var allItems = queryItems
        allItems.append(URLQueryItem(name: "apikey", value: configuration.apiKey))
        allItems.append(URLQueryItem(name: "nonce", value: credentials.nonce()))
        allItems.append(URLQueryItem(name: "timestamp", value: String(credentials.timestamp())))
        components.queryItems = allItems

        guard let unsignedURL = components.url else {
            throw LetterboxdError.invalidRequest("Could not assemble URL components for path: \(path)")
        }

        let signature = signer.signature(
            method: method,
            url: unsignedURL,
            body: body ?? ""
        )
        components.queryItems = allItems + [URLQueryItem(name: "signature", value: signature)]

        guard let finalURL = components.url else {
            throw LetterboxdError.invalidRequest("Could not assemble signed URL for path: \(path)")
        }

        var request = URLRequest(url: finalURL)
        request.httpMethod = method.uppercased()
        if let body {
            request.httpBody = Data(body.utf8)
        }
        if let contentType {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        return request
    }
}
