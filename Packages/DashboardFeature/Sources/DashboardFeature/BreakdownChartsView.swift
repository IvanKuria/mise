import SwiftUI
import MiseUI

/// A horizontal bar list for a labelled breakdown (genres): name, a gold bar
/// proportional to count, and the count. Hand-built for an editorial feel.
struct GenreBreakdownView: View {
    @Environment(\.miseTheme) private var theme

    let bars: [BreakdownBar]

    private var maxCount: Int { max(1, bars.map(\.count).max() ?? 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing(1.25)) {
            ForEach(bars) { bar in
                HStack(spacing: theme.spacing(1.5)) {
                    Text(bar.label)
                        .font(theme.font(.body))
                        .foregroundStyle(theme.textPrimary)
                        .frame(width: 104, alignment: .leading)
                        .lineLimit(1)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(theme.recess)
                            Capsule()
                                .fill(theme.accent)
                                .frame(width: max(6, geo.size.width * CGFloat(bar.count) / CGFloat(maxCount)))
                        }
                    }
                    .frame(height: 8)
                    Text("\(bar.count)")
                        .font(theme.font(.caption))
                        .monospacedDigit()
                        .foregroundStyle(theme.textSecondary)
                        .frame(width: 26, alignment: .trailing)
                }
            }
        }
    }
}

/// A vertical bar chart of films per decade (chronological).
struct DecadeBreakdownView: View {
    @Environment(\.miseTheme) private var theme

    let bars: [BreakdownBar]

    private var maxCount: Int { max(1, bars.map(\.count).max() ?? 1) }
    private let chartHeight: CGFloat = 130

    var body: some View {
        HStack(alignment: .bottom, spacing: theme.spacing(1.5)) {
            ForEach(bars) { bar in
                VStack(spacing: theme.spacing(0.75)) {
                    ZStack(alignment: .bottom) {
                        Color.clear.frame(height: chartHeight)
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(theme.accent)
                            .frame(height: max(6, chartHeight * CGFloat(bar.count) / CGFloat(maxCount)))
                            .overlay(alignment: .top) {
                                Text("\(bar.count)")
                                    .font(theme.font(.caption))
                                    .foregroundStyle(theme.textSecondary)
                                    .offset(y: -16)
                            }
                    }
                    Text(bar.label)
                        .font(theme.font(.caption))
                        .foregroundStyle(theme.textTertiary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}
