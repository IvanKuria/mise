import Foundation
import MiseCore

/// A sort order for diary entries. Every order is deterministic: entries that
/// compare equal on the primary key fall back to film name (case- and
/// diacritic-insensitive, ascending), then to the entry id, so the result is
/// stable regardless of input order.
public enum FilmSort: Sendable, Hashable, CaseIterable {
    case watchedDateDesc
    case watchedDateAsc
    case ratingDesc
    case ratingAsc
    case titleAsc
    case titleDesc
    case releaseYearDesc
    case releaseYearAsc
    case runtimeDesc
    case runtimeAsc

    /// A strict-ordering comparator (`true` when `a` should come before `b`).
    func areInIncreasingOrder(_ a: DiaryEntry, _ b: DiaryEntry) -> Bool {
        switch self {
        case .watchedDateDesc:
            return compareOptional(a.watchedDate, b.watchedDate, ascending: false, a, b)
        case .watchedDateAsc:
            return compareOptional(a.watchedDate, b.watchedDate, ascending: true, a, b)
        case .ratingDesc:
            return compareOptional(a.rating, b.rating, ascending: false, a, b)
        case .ratingAsc:
            return compareOptional(a.rating, b.rating, ascending: true, a, b)
        case .titleAsc:
            return tieBreak(a, b)
        case .titleDesc:
            // Reverse the primary (title) ordering, but keep the id tie-break
            // ascending so equal titles remain deterministic.
            let cmp = compareTitles(a, b)
            if cmp != .orderedSame { return cmp == .orderedDescending }
            return a.id < b.id
        case .releaseYearDesc:
            return compareOptional(a.film.releaseYear, b.film.releaseYear, ascending: false, a, b)
        case .releaseYearAsc:
            return compareOptional(a.film.releaseYear, b.film.releaseYear, ascending: true, a, b)
        case .runtimeDesc:
            return compareOptional(a.film.runtimeMinutes, b.film.runtimeMinutes, ascending: false, a, b)
        case .runtimeAsc:
            return compareOptional(a.film.runtimeMinutes, b.film.runtimeMinutes, ascending: true, a, b)
        }
    }

    /// Compares two optional primary keys. `nil` sorts last in both directions
    /// (so missing data is always at the bottom). Equal/both-nil keys fall back
    /// to the shared tie-break.
    private func compareOptional<T: Comparable>(
        _ lhs: T?,
        _ rhs: T?,
        ascending: Bool,
        _ a: DiaryEntry,
        _ b: DiaryEntry
    ) -> Bool {
        switch (lhs, rhs) {
        case let (l?, r?):
            if l != r { return ascending ? (l < r) : (l > r) }
            return tieBreak(a, b)
        case (nil, _?):
            return false // nil sorts after non-nil
        case (_?, nil):
            return true // non-nil sorts before nil
        case (nil, nil):
            return tieBreak(a, b)
        }
    }

    /// Deterministic tie-break: film name (case/diacritic-insensitive) ascending,
    /// then entry id ascending.
    private func tieBreak(_ a: DiaryEntry, _ b: DiaryEntry) -> Bool {
        let cmp = compareTitles(a, b)
        if cmp != .orderedSame { return cmp == .orderedAscending }
        return a.id < b.id
    }

    private func compareTitles(_ a: DiaryEntry, _ b: DiaryEntry) -> ComparisonResult {
        a.film.name.compare(
            b.film.name,
            options: [.caseInsensitive, .diacriticInsensitive],
            range: nil,
            locale: nil
        )
    }
}
