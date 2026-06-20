import SwiftUI
import MiseUI

/// A custom ratings histogram: a gold bar per half-star bucket (½…★★★★★),
/// hand-drawn for reliable rendering and an editorial feel.
struct RatingsHistogramView: View {
    @Environment(\.miseTheme) private var theme

    let histogram: [Int: Int]

    private var bars: [RatingBar] { DashboardFormat.ratingBars(histogram: histogram) }
    private var maxCount: Int { max(1, bars.map(\.count).max() ?? 1) }

    private let chartHeight: CGFloat = 150

    var body: some View {
        HStack(alignment: .bottom, spacing: theme.spacing(0.75)) {
            ForEach(bars) { bar in
                VStack(spacing: theme.spacing(0.75)) {
                    ZStack(alignment: .bottom) {
                        Color.clear.frame(height: chartHeight)
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(bar.count > 0 ? theme.accent : theme.hairline)
                            .frame(height: barHeight(bar.count))
                            .overlay(alignment: .top) {
                                if bar.count > 0 {
                                    Text("\(bar.count)")
                                        .font(theme.font(.caption))
                                        .foregroundStyle(theme.textSecondary)
                                        .offset(y: -16)
                                }
                            }
                    }
                    label(for: bar.halfStars)
                        .frame(height: 14)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func barHeight(_ count: Int) -> CGFloat {
        guard count > 0 else { return 2 }
        return max(6, chartHeight * CGFloat(count) / CGFloat(maxCount))
    }

    /// Label full-star buckets (2,4,6,8,10) as 1…5; leave half-star buckets blank.
    @ViewBuilder
    private func label(for halfStars: Int) -> some View {
        if halfStars % 2 == 0 {
            Text("\(halfStars / 2)★")
                .font(theme.font(.caption))
                .foregroundStyle(theme.textTertiary)
        } else {
            Color.clear.frame(width: 1)
        }
    }
}
