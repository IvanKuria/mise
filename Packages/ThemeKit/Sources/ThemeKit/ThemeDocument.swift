import Foundation

/// Errors raised while importing a ``ThemeDocument``.
public enum ThemeDocumentError: Error, Hashable, Sendable {
    /// The data was not valid JSON, or did not match the document shape.
    case malformedData
    /// The document declared a schema version this build cannot read.
    case unsupportedSchemaVersion(Int)
}

/// A versioned, shareable wrapper around a ``Theme``.
///
/// Use ``data()`` to export and ``init(data:)`` to import. Import rejects
/// malformed JSON and unsupported (e.g. future) schema versions.
public struct ThemeDocument: Codable, Hashable, Sendable {
    /// The schema version this build writes and is able to read.
    public static let currentSchemaVersion = 1

    /// The schema version of this document.
    public let schemaVersion: Int
    /// The wrapped theme.
    public let theme: Theme

    /// Creates a document at the current schema version.
    public init(theme: Theme) {
        self.schemaVersion = ThemeDocument.currentSchemaVersion
        self.theme = theme
    }

    /// Internal initializer allowing an explicit schema version (used by decode/tests).
    init(schemaVersion: Int, theme: Theme) {
        self.schemaVersion = schemaVersion
        self.theme = theme
    }

    /// Encodes the document to JSON for sharing.
    public func data() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }

    /// Decodes and validates a document from shared JSON.
    ///
    /// - Throws: ``ThemeDocumentError/malformedData`` for invalid/mismatched JSON,
    ///   or ``ThemeDocumentError/unsupportedSchemaVersion(_:)`` for a version this
    ///   build cannot read (anything other than ``currentSchemaVersion``).
    public init(data: Data) throws {
        let decoded: ThemeDocument
        do {
            decoded = try JSONDecoder().decode(ThemeDocument.self, from: data)
        } catch {
            throw ThemeDocumentError.malformedData
        }

        guard decoded.schemaVersion == ThemeDocument.currentSchemaVersion else {
            throw ThemeDocumentError.unsupportedSchemaVersion(decoded.schemaVersion)
        }

        self = decoded
    }
}
