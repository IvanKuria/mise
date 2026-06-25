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

/// Content view that owns the SwiftUI hosting view and drives hover via an
/// `NSTrackingArea`. Tracking areas fire `mouseEntered`/`mouseExited` for
/// inactive/borderless windows with NO Accessibility permission required —
/// unlike a global `NSEvent.mouseMoved` monitor, which can be gated by it.
final class TrackingHostView: NSView {
    /// Called when the cursor enters the notch surface (→ open).
    var onEntered: (() -> Void)?
    /// Called when the cursor leaves the notch surface (→ close).
    var onExited: (() -> Void)?

    private var trackingArea: NSTrackingArea?

    init(content: NSView) {
        super.init(frame: .zero)
        content.autoresizingMask = [.width, .height]
        addSubview(content)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea { removeTrackingArea(trackingArea) }
        // `.inVisibleRect` keeps the area in sync with the view's bounds as the
        // window resizes between collapsed and expanded; `.activeAlways` makes it
        // fire even when the app/window isn't active.
        let area = NSTrackingArea(
            rect: .zero,
            options: [.activeAlways, .mouseEnteredAndExited, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseEntered(with event: NSEvent) { onEntered?() }
    override func mouseExited(with event: NSEvent) { onExited?() }
}
