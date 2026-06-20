import Foundation
import MiseCore

// MARK: - Taste similarity

/// Similarity of two members' tastes over the films *both* have rated.
///
/// Metric: **Pearson correlation coefficient** over the shared rating vectors.
/// Pearson is mean-centred, so it measures whether the two members agree on the
/// *relative* ranking of films regardless of differing baselines (one member
/// who rates everything a star higher than another still correlates at +1).
/// Range is -1...1: +1 identical ordering, -1 opposite, 0 uncorrelated.
///
/// Returns 0 when fewer than `minimumSharedFilms` films are rated in both
/// diaries, or when either member's shared ratings have zero variance (a flat
/// vector has no correlation to measure).
///
/// Only diary entries that carry a `Rating` count; films logged without a
/// rating are ignored. Films are matched by `Film.id`.
public func tasteSimilarity(
    _ a: WatchHistory,
    _ b: WatchHistory,
    minimumSharedFilms: Int = 3
) -> Double {
    let ratingsA = ratingsByFilmID(a)
    let ratingsB = ratingsByFilmID(b)

    // Deterministic order: sort shared film ids.
    let sharedIDs = ratingsA.keys.filter { ratingsB.keys.contains($0) }.sorted()
    guard sharedIDs.count >= minimumSharedFilms else { return 0 }

    let xs = sharedIDs.map { ratingsA[$0]! }
    let ys = sharedIDs.map { ratingsB[$0]! }
    return pearson(xs, ys)
}

// MARK: - Internal helpers

/// Maps `Film.id` -> star rating for every diary entry that has a rating.
/// If the same film appears more than once, the last entry wins (deterministic
/// because diary order is preserved).
func ratingsByFilmID(_ history: WatchHistory) -> [String: Double] {
    var result: [String: Double] = [:]
    for entry in history.diary {
        guard let rating = entry.rating else { continue }
        result[entry.film.id] = rating.stars
    }
    return result
}

/// Pearson correlation of two equal-length vectors. Returns 0 if either vector
/// has zero variance (no correlation is defined).
func pearson(_ xs: [Double], _ ys: [Double]) -> Double {
    let n = Double(xs.count)
    guard n > 0 else { return 0 }

    let meanX = xs.reduce(0, +) / n
    let meanY = ys.reduce(0, +) / n

    var covariance = 0.0
    var varX = 0.0
    var varY = 0.0
    for i in xs.indices {
        let dx = xs[i] - meanX
        let dy = ys[i] - meanY
        covariance += dx * dy
        varX += dx * dx
        varY += dy * dy
    }

    let denominator = (varX * varY).squareRoot()
    guard denominator > 0 else { return 0 }
    return covariance / denominator
}
