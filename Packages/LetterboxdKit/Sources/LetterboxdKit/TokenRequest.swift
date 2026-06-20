import Foundation

/// Pure helpers for the OAuth2 client-credentials token call. Isolated so the
/// form-encoded body construction is unit-testable.
enum TokenRequest {
    /// The form-encoded body for a client-credentials grant.
    /// Letterboxd authenticates the app via the signed `apikey`, so the body is
    /// just the grant type.
    static let formBody = "grant_type=client_credentials"

    static let contentType = "application/x-www-form-urlencoded"

    static let path = "auth/token"
}

/// The token endpoint response. `expires_in` is seconds-to-expiry.
// TODO: verify against live API — field names and the presence of expires_in.
struct TokenResponseDTO: Decodable, Sendable {
    let accessToken: String
    let tokenType: String?
    let expiresIn: Int?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
    }
}

/// A cached access token with its computed expiry instant.
struct CachedToken: Sendable {
    let value: String
    let expiresAt: Date

    func isValid(now: Date, leeway: TimeInterval = 30) -> Bool {
        now.addingTimeInterval(leeway) < expiresAt
    }
}
