import Foundation
import Testing
@testable import LetterboxdKit

@Suite("LetterboxdRequestBuilder")
struct RequestBuilderTests {

    private func makeBuilder() -> LetterboxdRequestBuilder {
        let config = LetterboxdConfiguration(apiKey: "KEY", apiSecret: "shhh")
        let creds = FixedCredentialsProvider(fixedNonce: "N", fixedTimestamp: 100)
        return LetterboxdRequestBuilder(configuration: config, credentials: creds)
    }

    @Test("GET request carries apikey, nonce, timestamp, and signature")
    func signingParams() throws {
        let builder = makeBuilder()
        let request = try builder.makeRequest(method: "GET", path: "film/abc")
        let comps = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
        let items = Dictionary(uniqueKeysWithValues: (comps.queryItems ?? []).map { ($0.name, $0.value) })

        #expect(items["apikey"] == "KEY")
        #expect(items["nonce"] == "N")
        #expect(items["timestamp"] == "100")
        #expect(items["signature"] != nil)
        #expect(request.httpMethod == "GET")
    }

    @Test("signature is computed over the URL WITHOUT the signature param")
    func signatureExcludesItself() throws {
        let builder = makeBuilder()
        let request = try builder.makeRequest(method: "GET", path: "film/abc")
        let comps = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!

        // Rebuild the unsigned URL (everything but the signature item).
        var unsigned = comps
        unsigned.queryItems = (comps.queryItems ?? []).filter { $0.name != "signature" }
        let signer = RequestSigner(sharedSecret: "shhh")
        let expected = signer.signature(method: "GET", url: unsigned.url!, body: "")

        let actual = comps.queryItems?.first { $0.name == "signature" }?.value
        #expect(actual == expected)
    }

    @Test("endpoint query items precede the signing params")
    func endpointQueryItems() throws {
        let builder = makeBuilder()
        let request = try builder.makeRequest(
            method: "GET",
            path: "log-entries",
            queryItems: [URLQueryItem(name: "member", value: "MEM1")]
        )
        let comps = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
        let names = (comps.queryItems ?? []).map(\.name)
        #expect(names.first == "member")
        #expect(names.contains("apikey"))
        #expect(names.last == "signature")
    }

    @Test("POST body and content-type are set")
    func postBody() throws {
        let builder = makeBuilder()
        let request = try builder.makeRequest(
            method: "POST",
            path: "auth/token",
            body: "grant_type=client_credentials",
            contentType: "application/x-www-form-urlencoded"
        )
        #expect(request.httpMethod == "POST")
        #expect(request.httpBody == Data("grant_type=client_credentials".utf8))
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/x-www-form-urlencoded")
    }

    @Test("path resolves against the base URL")
    func basePath() throws {
        let builder = makeBuilder()
        let request = try builder.makeRequest(method: "GET", path: "member/MEM1/statistics")
        #expect(request.url!.absoluteString.hasPrefix("https://api.letterboxd.com/api/v0/member/MEM1/statistics"))
    }
}

@Suite("TokenRequest")
struct TokenRequestTests {
    @Test("form body is the client-credentials grant")
    func body() {
        #expect(TokenRequest.formBody == "grant_type=client_credentials")
        #expect(TokenRequest.contentType == "application/x-www-form-urlencoded")
        #expect(TokenRequest.path == "auth/token")
    }
}
