import Foundation

/// A tiny deterministic PRNG (SplitMix64) so seeded selection is reproducible
/// across runs and platforms, independent of system randomness.
struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        // Avoid a degenerate all-zero state.
        self.state = seed &+ 0x9E37_79B9_7F4A_7C15
    }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

extension Array {
    /// A deterministic Fisher–Yates shuffle driven by the seeded RNG.
    func seededShuffled(seed: UInt64) -> [Element] {
        var rng = SeededRNG(seed: seed)
        var result = self
        guard result.count > 1 else { return result }
        for i in stride(from: result.count - 1, to: 0, by: -1) {
            let j = Int(rng.next() % UInt64(i + 1))
            result.swapAt(i, j)
        }
        return result
    }
}
