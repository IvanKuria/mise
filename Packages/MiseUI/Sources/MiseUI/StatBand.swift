import SwiftUI

/// One metric: a large value (with optional unit) over a small uppercase label.
public struct StatItem: Identifiable, Hashable, Sendable {
    public let id = UUID()
    public let value: String
    public let unit: String?
    public let label: String
    public let emphasis: Bool

    public init(value: String, unit: String? = nil, label: String, emphasis: Bool = false) {
        self.value = value
        self.unit = unit
        self.label = label
        self.emphasis = emphasis
    }
}

/// An editorial "stat masthead": big numerals with tiny uppercase labels,
/// separated by vertical hairlines — no per-stat box. Replaces generic KPI tiles.
public struct StatBand: View {
    @Environment(\.miseTheme) private var theme
    private let items: [StatItem]

    public init(_ items: [StatItem]) { self.items = items }

    public var body: some View {
        HStack(alignment: .center, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                stat(item)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if index < items.count - 1 {
                    Rectangle()
                        .fill(theme.hairline)
                        .frame(width: 1)
                        .padding(.vertical, theme.spacing(0.5))
                }
            }
        }
        .padding(.vertical, theme.spacing(2.5))
        .padding(.horizontal, theme.spacing(3))
        .miseCard(theme)
    }

    private func stat(_ item: StatItem) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing(0.75)) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(item.value)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(item.emphasis ? theme.accent : theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if let unit = item.unit {
                    Text(unit)
                        .font(theme.font(.headline))
                        .foregroundStyle(theme.textSecondary)
                }
            }
            .lineLimit(1)
            Text(item.label.uppercased())
                .font(theme.font(.caption))
                .tracking(1.4)
                .foregroundStyle(theme.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, theme.spacing(2))
    }
}
