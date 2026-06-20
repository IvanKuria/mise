import Foundation
import Testing
@testable import ThemeKit

@Suite("RGBAColor")
struct RGBAColorTests {
    @Test("parses #RRGGBB and round-trips")
    func parseRGB() throws {
        let c = try #require(RGBAColor(hex: "#FF8000"))
        #expect(abs(c.red - 1.0) < 0.001)
        #expect(abs(c.green - 0.5019) < 0.001)
        #expect(abs(c.blue - 0.0) < 0.001)
        #expect(abs(c.alpha - 1.0) < 0.001)
        #expect(c.hexString == "#FF8000FF")
    }

    @Test("parses #RRGGBBAA with alpha")
    func parseRGBA() throws {
        let c = try #require(RGBAColor(hex: "#00FF0080"))
        #expect(abs(c.red - 0.0) < 0.001)
        #expect(abs(c.green - 1.0) < 0.001)
        #expect(abs(c.blue - 0.0) < 0.001)
        #expect(abs(c.alpha - 0.5019) < 0.001)
    }

    @Test("is case-insensitive and tolerates missing leading #")
    func caseAndPrefix() throws {
        let a = try #require(RGBAColor(hex: "ff8000"))
        let b = try #require(RGBAColor(hex: "#FF8000"))
        #expect(a == b)
    }

    @Test("round-trips a parsed hex string back to an equal color")
    func roundTrip() throws {
        let original = try #require(RGBAColor(hex: "#123456AB"))
        let reparsed = try #require(RGBAColor(hex: original.hexString))
        #expect(original == reparsed)
    }

    @Test("rejects invalid hex strings", arguments: [
        "", "#", "#XYZ", "#12", "#12345", "#1234567", "12345G", "#GGGGGG", "not-a-color",
    ])
    func rejectsInvalid(_ bad: String) {
        #expect(RGBAColor(hex: bad) == nil)
    }

    @Test("clamps stored components to 0...1 on direct init")
    func clamps() {
        let c = RGBAColor(red: 2.0, green: -1.0, blue: 0.5, alpha: 9.0)
        #expect(c.red == 1.0)
        #expect(c.green == 0.0)
        #expect(c.blue == 0.5)
        #expect(c.alpha == 1.0)
    }

    @Test("encodes and decodes via Codable")
    func codable() throws {
        let c = try #require(RGBAColor(hex: "#AABBCCDD"))
        let data = try JSONEncoder().encode(c)
        let back = try JSONDecoder().decode(RGBAColor.self, from: data)
        #expect(c == back)
    }
}
