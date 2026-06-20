import SwiftUI
import Charts
import StatsEngine
import MiseUI

/// A Swift Charts bar chart of the ratings histogram across half-star buckets,
/// labelled with star glyphs along the x-axis.
struct RatingsHistogramView: View {
    @Environment(\.miseTheme) private var theme

    let histogram: [Int: Int]

    private var bars: [RatingBar] { DashboardFormat.ratingBars(histogram: histogram) }

    var body: some View {
        Chart(bars) { bar in
            BarMark(
                x: .value("Rating", bar.halfStars),
                y: .value("Films", bar.count),
                width: .ratio(0.7)
            )
            .foregroundStyle(theme.accent.gradient)
            .cornerRadius(theme.smallCornerRadius)
        }
        .chartXScale(domain: 0.5...10.5)
        .chartXAxis {
            AxisMarks(values: Array(stride(from: 2, through: 10, by: 2))) { value in
                AxisValueLabel {
                    if let half = value.as(Int.self) {
                        Text(DashboardFormat.starGlyphs(halfStars: half))
                            .font(theme.font(.caption))
                            .foregroundStyle(theme.secondaryText)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine().foregroundStyle(theme.posterBorder.opacity(0.3))
                AxisValueLabel().foregroundStyle(theme.secondaryText)
            }
        }
        .frame(height: 200)
    }
}
