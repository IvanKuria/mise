import SwiftUI

/// A themed metric tile: a big value with a title above and optional caption below.
public struct StatCard: View {
    @Environment(\.miseTheme) private var theme

    private let title: String
    private let value: String
    private let caption: String?

    public init(title: String, value: String, caption: String? = nil) {
        self.title = title
        self.value = value
        self.caption = caption
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing(0.5)) {
            Text(title.uppercased())
                .font(theme.font(.caption))
                .tracking(0.8)
                .foregroundStyle(theme.secondaryText)
            Text(value)
                .font(theme.font(.title))
                .foregroundStyle(theme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            if let caption {
                Text(caption)
                    .font(theme.font(.caption))
                    .foregroundStyle(theme.secondaryAccent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(theme.spacing(1.5))
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                .fill(theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                .strokeBorder(theme.posterBorder.opacity(0.6), lineWidth: 1)
        )
    }
}

#Preview("StatCard") {
    HStack(spacing: 16) {
        StatCard(title: "Films", value: "1,284", caption: "this year")
        StatCard(title: "Hours", value: "2,041")
    }
    .padding(32)
    .background(MiseTheme(.noir).background)
    .miseTheme(.noir)
}
