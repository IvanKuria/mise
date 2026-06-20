import Foundation
import Testing
@testable import LetterboxdKit

@Suite("RequestSigner")
struct RequestSignerTests {

    @Test("HMAC-SHA256 hex matches a known vector")
    func knownVector() {
        let signer = RequestSigner(sharedSecret: "secretkey")
        // Independently computed: HMAC-SHA256("secretkey", "hello")
        #expect(signer.hmacHex(message: "hello") ==
                "122b99e68dd9cabbd464c943550399cad150790bcd3d94f526b92fa29fb762bc")
    }

    @Test("message joins method, url, body with NUL separator in order")
    func messageConstruction() {
        let signer = RequestSigner(sharedSecret: "x")
        let url = URL(string: "https://example.com/a?b=c")!
        let msg = signer.message(method: "get", url: url, body: "body")
        #expect(msg == "GET\u{0}https://example.com/a?b=c\u{0}body")
    }

    @Test("signature matches a known vector over the full signing message")
    func signatureVector() {
        let signer = RequestSigner(sharedSecret: "shhh")
        let url = URL(string: "https://api.letterboxd.com/api/v0/film/abc?apikey=KEY&nonce=N&timestamp=100")!
        let sig = signer.signature(method: "GET", url: url, body: "")
        // Independently computed HMAC over "GET\0<url>\0".
        #expect(sig == "e10ec493182b4c3960abebae4351de6cbe7a3c4dee8562f63e149327ae930930")
    }

    @Test("empty body is signed as empty string for GET")
    func emptyBody() {
        let signer = RequestSigner(sharedSecret: "x")
        let url = URL(string: "https://example.com/")!
        let msg = signer.message(method: "GET", url: url, body: "")
        #expect(msg == "GET\u{0}https://example.com/\u{0}")
    }
}
