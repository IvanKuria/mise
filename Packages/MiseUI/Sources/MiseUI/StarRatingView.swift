import SwiftUI
import MiseCore

/// Renders a `Rating` as five themed stars with half-star support, drawn so the
/// fill picks up the theme accent. Shows a muted placeholder for `nil`.
public struct StarRatingView: View {
    @Environment(\.miseTheme) private var theme

    private let rating: Rating?
    private let starSize: CGFloat

    public init(rating: Rating?, starSize: CGFloat = 14) {
        self.rating = rating
        self.starSize = starSize
    }

    public var body: some View {
        if let rating {
            HStack(spacing: starSize * 0.15) {
                ForEach(0..<5, id: \.self) { index in
                    star(for: StarRatingView.fill(forStarIndex: index, halfStars: rating.halfStars))
                }
            }
            .accessibilityElement()
            .accessibilityLabel("\(rating.stars) out of 5 stars")
        } else {
            Text("—")
                .font(.system(size: starSize))
                .foregroundStyle(theme.secondaryText.opacity(0.5))
                .accessibilityLabel("No rating")
        }
    }

    /// Pure: how much of the star at `index` (0...4) should be filled given the
    /// rating's half-star count. Returns 0 (empty), 0.5 (half) or 1 (full).
    public static func fill(forStarIndex index: Int, halfStars: Int) -> Double {
        let starHalves = halfStars - index * 2
        if starHalves >= 2 { return 1.0 }
        if starHalves == 1 { return 0.5 }
        return 0.0
    }

    @ViewBuilder
    private func star(for fill: Double) -> some View {
        Group {
            switch fill {
            case 1.0:
                Image(systemName: "star.fill").foregroundStyle(theme.accent)
            case 0.5:
                Image(systemName: "star.leadinghalf.filled").foregroundStyle(theme.accent)
            default:
                Image(systemName: "star").foregroundStyle(theme.secondaryAccent.opacity(0.4))
            }
        }
        .font(.system(size: starSize))
    }
}

#Preview("StarRatingView") {
    VStack(alignment: .leading, spacing: 12) {
        StarRatingView(rating: Rating(halfStars: 9))
        StarRatingView(rating: Rating(halfStars: 6))
        StarRatingView(rating: nil)
    }
    .padding(32)
    .background(MiseTheme(.noir).background)
    .miseTheme(.noir)
}
