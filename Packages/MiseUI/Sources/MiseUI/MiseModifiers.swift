import SwiftUI

public extension View {
    /// An elevated translucent card: soft fill, hairline border, soft shadow.
    func miseCard(_ theme: MiseTheme, radius: CGFloat? = nil) -> some View {
        let r = radius ?? theme.cornerRadius
        return self
            .background(
                RoundedRectangle(cornerRadius: r, style: .continuous).fill(theme.cardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: r, style: .continuous)
                    .strokeBorder(theme.hairline, lineWidth: 1)
            )
            .shadow(color: theme.shadowColor, radius: theme.shadowRadius, x: 0, y: theme.shadowY)
    }

    /// A recessed input well (for text fields and tracks).
    func miseField(_ theme: MiseTheme) -> some View {
        let r = theme.smallCornerRadius
        return self
            .background(
                RoundedRectangle(cornerRadius: r, style: .continuous).fill(theme.recess)
            )
            .overlay(
                RoundedRectangle(cornerRadius: r, style: .continuous)
                    .strokeBorder(theme.hairline, lineWidth: 1)
            )
    }
}

/// A premium sidebar/list row: hover fill and a bright selection pill with an
/// optional inline action revealed when selected (the reference's pattern).
public struct MiseRow<Content: View, Action: View>: View {
    @Environment(\.miseTheme) private var theme
    private let isSelected: Bool
    private let content: Content
    private let action: Action
    @State private var hovering = false

    public init(
        isSelected: Bool,
        @ViewBuilder content: () -> Content,
        @ViewBuilder action: () -> Action = { EmptyView() }
    ) {
        self.isSelected = isSelected
        self.content = content()
        self.action = action()
    }

    public var body: some View {
        HStack(spacing: theme.spacing(1)) {
            content
            Spacer(minLength: 0)
            if isSelected { action }
        }
        .padding(.horizontal, theme.spacing(1.5))
        .padding(.vertical, theme.spacing(1.25))
        .background(
            RoundedRectangle(cornerRadius: theme.smallCornerRadius, style: .continuous)
                .fill(isSelected ? theme.selectionFill : (hovering ? theme.hoverFill : .clear))
        )
        .shadow(
            color: isSelected ? theme.shadowColor.opacity(0.6) : .clear,
            radius: isSelected ? 10 : 0, x: 0, y: isSelected ? 4 : 0
        )
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .animation(theme.hoverMotion, value: hovering)
        .animation(theme.motion, value: isSelected)
    }
}
