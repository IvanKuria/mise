import SwiftUI

/// An editorial section header: a strong title with an optional subtitle and a
/// thin accent rule that anchors content below it.
public struct SectionHeader: View {
    @Environment(\.miseTheme) private var theme

    private let title: String
    private let subtitle: String?

    public init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: theme.spacing(1.25)) {
            Text(title)
                .font(theme.font(.title))
                .foregroundStyle(theme.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(theme.font(.caption))
                    .foregroundStyle(theme.textTertiary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("SectionHeader") {
    SectionHeader("Recently Watched", subtitle: "Last 30 days")
        .padding(32)
        .background(MiseTheme(.noir).background)
        .miseTheme(.noir)
}
