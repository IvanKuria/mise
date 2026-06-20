import Foundation

/// The state machine for the first-run experience. Owns the user's entered
/// Letterboxd handle, an optional TMDB API key, and the live sync `status`.
///
/// All normalization/validation logic is exposed as pure static functions so it
/// can be unit-tested without constructing the `@MainActor` model.
@MainActor
@Observable
public final class OnboardingModel {

    /// The lifecycle of a first-run sync.
    public enum Status: Sendable, Equatable {
        /// Nothing has happened yet; the form is editable.
        case idle
        /// A sync is in flight. `progress` is `0...1`; `message` is human-readable.
        case syncing(progress: Double, message: String)
        /// The sync failed with a user-facing message.
        case failed(String)
        /// The sync completed successfully.
        case done

        /// Whether a sync is currently running.
        public var isSyncing: Bool {
            if case .syncing = self { return true }
            return false
        }
    }

    /// The raw text bound to the handle field. May contain a pasted URL; it is
    /// normalized lazily via ``normalizedHandle``.
    public var handle: String

    /// The raw text bound to the optional TMDB key field.
    public var tmdbKey: String

    /// The current sync status. The host app drives this in response to `onSubmit`.
    public var status: Status

    public init(
        handle: String = "",
        tmdbKey: String = "",
        status: Status = .idle
    ) {
        self.handle = handle
        self.tmdbKey = tmdbKey
        self.status = status
    }

    // MARK: Derived state

    /// The cleaned-up handle (URL stripped, `@`/whitespace removed), or `nil` if
    /// the current input does not yield a valid handle.
    public var normalizedHandle: String? {
        Self.normalizeHandle(handle)
    }

    /// The trimmed TMDB key, or `nil` when blank. Whitespace-only counts as blank.
    public var normalizedTMDBKey: String? {
        Self.normalizeTMDBKey(tmdbKey)
    }

    /// Whether the form can be submitted: a valid handle and not already syncing.
    public var canSubmit: Bool {
        normalizedHandle != nil && !status.isSyncing
    }

    // MARK: Pure logic (unit-tested)

    /// Normalizes free-form handle input into a bare Letterboxd username.
    ///
    /// Accepts:
    /// - a plain handle (`"davidfincher"`)
    /// - a leading `@` (`"@davidfincher"`)
    /// - a full or partial profile URL
    ///   (`"https://letterboxd.com/davidfincher/"`, `"letterboxd.com/davidfincher/films"`)
    ///
    /// Returns `nil` when no valid handle can be extracted. A valid handle is
    /// non-empty and contains only `[A-Za-z0-9_]`.
    public nonisolated static func normalizeHandle(_ raw: String) -> String? {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return nil }

        // Drop a URL scheme if present.
        if let schemeRange = s.range(of: "://") {
            s = String(s[schemeRange.upperBound...])
        }

        // If this looks like a letterboxd.com URL/path, take the first path
        // component after the host.
        let lowered = s.lowercased()
        if let hostRange = lowered.range(of: "letterboxd.com/") {
            let afterHost = s[hostRange.upperBound...]
            // First non-empty path segment is the username.
            let segment = afterHost.split(separator: "/", omittingEmptySubsequences: true).first
            s = segment.map(String.init) ?? ""
        }

        // Strip a leading "@" and any stray surrounding slashes/whitespace.
        s = s.trimmingCharacters(in: CharacterSet(charactersIn: "/ \t\n@"))
        if s.hasPrefix("@") { s.removeFirst() }

        guard isValidHandle(s) else { return nil }
        return s
    }

    /// Whether a bare handle is syntactically valid: non-empty and only
    /// letters, digits, or underscores (Letterboxd's username charset).
    public nonisolated static func isValidHandle(_ handle: String) -> Bool {
        guard !handle.isEmpty else { return false }
        let allowed = CharacterSet(charactersIn:
            "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_")
        return handle.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    /// Trims a TMDB key and returns `nil` when blank.
    public nonisolated static func normalizeTMDBKey(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
