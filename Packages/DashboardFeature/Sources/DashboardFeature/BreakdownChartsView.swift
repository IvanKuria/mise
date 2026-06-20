import SwiftUI
import Charts
import MiseUI

/// A horizontal bar chart for a labelled breakdown (genres), coloured by the
/// theme accent with the count as the value.
struct GenreBreakdownView: View {
    @Environment(\.miseTheme) private var theme

    let bars: [BreakdownBar]

    var body: some View {
        Chart(bars) { bar in
            BarMark(
                x: .value("Films", bar.count),
                y: .value("Genre", bar.label)
            )
            .foregroundStyle(theme.accent.gradient)
            .cornerRadius(theme.smallCornerRadius)
            .annotation(position: .trailing, alignment: .leading) {
                Text("\(bar.count)")
                    .font(theme.font(.caption))
                    .foregroundStyle(theme.secondaryText)
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .foregroundStyle(theme.primaryText)
            }
        }
        .chartXAxis(.hidden)
        .frame(height: max(120, CGFloat(bars.count) * 30))
    }
}

/// An area chart of films per decade (chronological), evoking the shape of a
/// viewing era timeline.
struct DecadeBreakdownView: View {
    @Environment(\.miseTheme) private var theme

    let bars: [BreakdownBar]

    var body: some View {
        Chart(bars) { bar in
            AreaMark(
                x: .value("Decade", bar.label),
                y: .value("Films", bar.count)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [theme.accent.opacity(0.55), theme.accent.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)

            LineMark(
                x: .value("Decade", bar.label),
                y: .value("Films", bar.count)
            )
            .foregroundStyle(theme.accent)
            .interpolationMethod(.catmullRom)

            PointMark(
                x: .value("Decade", bar.label),
                y: .value("Films", bar.count)
            )
            .foregroundStyle(theme.accent)
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .foregroundStyle(theme.secondaryText)
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
