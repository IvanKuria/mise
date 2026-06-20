import Foundation
import Testing
@testable import ThemeKit

@Suite("ThemeDocument")
struct ThemeDocumentTests {
    @Test("wraps a theme at the current schema version")
    func defaultsToCurrentVersion() {
        let doc = ThemeDocument(theme: .noir)
        #expect(doc.schemaVersion == ThemeDocument.currentSchemaVersion)
        #expect(doc.theme == .noir)
    }

    @Test("round-trips through data()/init(data:)")
    func roundTrip() throws {
        for theme in Theme.allBuiltIn {
            let doc = ThemeDocument(theme: theme)
            let data = try doc.data()
            let back = try ThemeDocument(data: data)
            #expect(back.theme == theme)
            #expect(back.schemaVersion == ThemeDocument.currentSchemaVersion)
        }
    }

    @Test("rejects malformed JSON")
    func rejectsMalformed() {
        let garbage = Data("this is not json".utf8)
        #expect(throws: ThemeDocumentError.malformedData) {
            _ = try ThemeDocument(data: garbage)
        }
    }

    @Test("rejects empty data")
    func rejectsEmpty() {
        #expect(throws: ThemeDocumentError.malformedData) {
            _ = try ThemeDocument(data: Data())
        }
    }

    @Test("rejects valid JSON that is not a ThemeDocument")
    func rejectsWrongShape() {
        let wrong = Data(#"{"hello":"world"}"#.utf8)
        #expect(throws: ThemeDocumentError.malformedData) {
            _ = try ThemeDocument(data: wrong)
        }
    }

    @Test("rejects a future schema version")
    func rejectsFutureVersion() throws {
        let future = ThemeDocument.currentSchemaVersion + 1
        let json = """
        {"schemaVersion": \(future), "theme": \(themeJSON())}
        """
        let data = Data(json.utf8)
        #expect(throws: ThemeDocumentError.unsupportedSchemaVersion(future)) {
            _ = try ThemeDocument(data: data)
        }
    }

    @Test("rejects a zero/negative schema version")
    func rejectsBadVersion() throws {
        let json = """
        {"schemaVersion": 0, "theme": \(themeJSON())}
        """
        #expect(throws: ThemeDocumentError.unsupportedSchemaVersion(0)) {
            _ = try ThemeDocument(data: Data(json.utf8))
        }
    }

    // Serializes a known-good theme to JSON for embedding in test fixtures.
    private func themeJSON() -> String {
        let data = try! JSONEncoder().encode(Theme.noir)
        return String(decoding: data, as: UTF8.self)
    }
}
