import SwiftUI

/// A small themed pill, optionally shown as selected (filled with the accent).
public struct Chip: View {
    @Environment(\.miseTheme) private var theme

    private let text: String
    private let selected: Bool

    public init(_ text: String, selected: Bool = false) {
        self.text = text
        self.selected = selected
    }

    public var body: some View {
        Text(text)
            .font(theme.font(.caption))
            .foregroundStyle(selected ? theme.background : theme.primaryText)
            .padding(.horizontal, theme.spacing(1.25))
            .padding(.vertical, theme.spacing(0.625))
            .background(
                Capsule(style: .continuous)
                    .fill(selected ? theme.accent : theme.surface)
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(
                        selected ? Color.clear : theme.posterBorder,
                        lineWidth: 1
                    )
            )
    }
}

/// A read-only tag pill (a non-selectable `Chip`, prefixed with `#`).
public struct TagView: View {
    private let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Chip("#\(text)", selected: false)
    }
}

#Preview("Chip / TagView") {
    HStack(spacing: 8) {
        Chip("Horror", selected: true)
        Chip("Drama")
        TagView("rewatch")
    }
    .padding(32)
    .background(MiseTheme(.noir).background)
    .miseTheme(.noir)
}
