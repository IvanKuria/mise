import Foundation
import CryptoKit

/// Builds the Letterboxd request signature.
///
/// Letterboxd signs each request with an HMAC-SHA256 over a message formed by
/// joining, with the NUL separator `\u{0}`:
///
///   `UPPERCASED_HTTP_METHOD` + `\u{0}` + full request URL (including the
///   `apikey`/`nonce`/`timestamp` query params) + `\u{0}` + request body string
///   (empty for GET).
///
/// The signature is the lowercase hex of the HMAC keyed by the API shared
/// secret. The message-construction is isolated here (separator and component
/// order as named constants) so it can be corrected after a live spike.
///
// TODO: verify against live API — confirm separator, component order, whether
// the URL is signed pre- or post-percent-encoding, and body handling for writes.
public struct RequestSigner: Sendable {
    /// The shared API secret used as the HMAC key.
    public let sharedSecret: String

    /// The NUL component separator. Isolated so it can be corrected post-spike.
    public static let separator = "\u{0}"

    public init(sharedSecret: String) {
        self.sharedSecret = sharedSecret
    }

    /// Construct the exact message string that gets HMAC'd. Pure and testable.
    /// - Parameters:
    ///   - method: HTTP method; uppercased internally.
    ///   - url: the full request URL, query params already attached.
    ///   - body: the request body string (empty for GET).
    public func message(method: String, url: URL, body: String) -> String {
        // Component order is load-bearing; keep it explicit.
        let components: [String] = [
            method.uppercased(),
            url.absoluteString,
            body,
        ]
        return components.joined(separator: Self.separator)
    }

    /// Lowercase hex of HMAC-SHA256(sharedSecret, message).
    public func signature(method: String, url: URL, body: String) -> String {
        let msg = message(method: method, url: url, body: body)
        return hmacHex(message: msg)
    }

    /// Lowercase hex HMAC-SHA256 of an arbitrary message with the shared secret.
    /// Exposed so the signing primitive can be tested against a known vector.
    public func hmacHex(message: String) -> String {
        let key = SymmetricKey(data: Data(sharedSecret.utf8))
        let mac = HMAC<SHA256>.authenticationCode(for: Data(message.utf8), using: key)
        return mac.map { String(format: "%02x", $0) }.joined()
    }
}
