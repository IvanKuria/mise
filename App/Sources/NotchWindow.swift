import AppKit

/// A borderless, transparent window pinned at the notch. Patterned on NotchDrop
/// (MIT): floats above the menu bar, joins all spaces, doesn't steal focus
/// unless it needs key input (for the inline username editor).
final class NotchWindow: NSWindow {
    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovable = false
        isMovableByWindowBackground = false
        level = .statusBar + 8
        collectionBehavior = [.fullScreenAuxiliary, .stationary, .canJoinAllSpaces, .ignoresCycle]
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        // The notch is physically dark; force a dark appearance for vibrant
        // foreground colors regardless of the system setting.
        appearance = NSAppearance(named: .darkAqua)
    }

    // Allow the inline username field to receive keystrokes.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
