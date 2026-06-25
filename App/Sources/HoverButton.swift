import SwiftUI

/// A borderless icon button with boring.notch's hover treatment: a capsule that
/// fills with a faint gray on hover (no scale), smooth 0.3s. Plain button style.
struct HoverButton: View {
    let systemName: String
    var size: CGFloat = 28
    var weight: Font.Weight = .semibold
    var fontSize: CGFloat = 12
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Capsule(style: .continuous)
                    .fill(hovering ? Color.gray.opacity(0.22) : .clear)
                Image(systemName: systemName)
                    .font(.system(size: fontSize, weight: weight))
                    .foregroundStyle(NotchStyle.textPrimary)
                    .contentTransition(.symbolEffect)
            }
            .frame(width: size, height: size)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(.smooth(duration: 0.3), value: hovering)
    }
}
