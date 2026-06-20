import Foundation
import MiseCore
import WatchlistPlanner

/// Pure helpers that explain *why* a film was picked, for the hero card.
public enum PickRationale {

    /// A short, human reason a film fits tonight's criteria. Falls back to a
    /// friendly default when no criteria are active.
    public static func reason(
        for item: WatchlistItem,
        criteria: TonightCriteria,
        availability: StreamingAvailability,
        ranking: Ranking
    ) -> String {
        var parts: [String] = []
        let film = item.film

        if criteria.maxRuntimeMinutes != nil, let runtime = film.runtimeMinutes {
            parts.append("\(runtime) min — fits your window")
        }

        if !criteria.requiredServices.isEmpty {
            let have = availability.services(for: film.id)
                .intersection(criteria.requiredServices)
            if let service = have.sorted().first {
                parts.append("streaming on \(service)")
            }
        }

        if !criteria.genres.isEmpty {
            let wanted = Set(criteria.genres.map { $0.lowercased() })
            let matched = film.genres
                .first { wanted.contains($0.name.lowercased()) }?
                .name
            if let matched {
                parts.append(matched.lowercased())
            }
        }

        if criteria.minLetterboxdAverage != nil, let avg = film.letterboxdAverageRating {
            parts.append(String(format: "%.1f★ on Letterboxd", avg))
        }

        if parts.isEmpty {
            switch ranking {
            case .shortestFirst:
                if let runtime = film.runtimeMinutes {
                    return "Shortest on your list at \(runtime) min."
                }
            case .highestRated:
                if let avg = film.letterboxdAverageRating {
                    return String(format: "Your highest-rated pick at %.1f★.", avg)
                }
            case .random:
                break
            }
            return "Pulled from your watchlist — press reroll for another."
        }

        return parts.joined(separator: " · ").prefix(1).uppercased()
            + parts.joined(separator: " · ").dropFirst()
    }

    /// A compact metadata line for the hero: "1979 · 162 min · 4.4★".
    public static func metaLine(for film: Film) -> String {
        var bits: [String] = []
        if let year = film.releaseYear { bits.append(String(year)) }
        if let runtime = film.runtimeMinutes { bits.append("\(runtime) min") }
        if let avg = film.letterboxdAverageRating {
            bits.append(String(format: "%.1f★", avg))
        }
        return bits.joined(separator: " · ")
    }
}
