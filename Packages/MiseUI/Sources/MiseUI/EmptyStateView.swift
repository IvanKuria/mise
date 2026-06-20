import SwiftUI

/// A centered, themed empty state: an SF Symbol, a title, and a supporting message.
public struct EmptyStateView: View {
    @Environment(\.miseTheme) private var theme

    private let symbol: String
    private let title: String
    private let message: String

    public init(symbol: String, title: String, message: String) {
        self.symbol = symbol
        self.title = title
        self.message = message
    }

    public var body: some View {
        VStack(spacing: theme.spacing(1.5)) {
            Image(systemName: symbol)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(theme.secondaryAccent)
            VStack(spacing: theme.spacing(0.5)) {
                Text(title)
                    .font(theme.font(.headline))
                    .foregroundStyle(theme.primaryText)
                Text(message)
                    .font(theme.font(.body))
                    .foregroundStyle(theme.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(theme.spacing(3))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("EmptyStateView") {
    EmptyStateView(
        symbol: "film.stack",
        title: "No films yet",
        message: "Sync your Letterboxd diary to see your watch history here."
    )
    .frame(width: 420, height: 320)
    .background(MiseTheme(.noir).background)
    .miseTheme(.noir)
}
