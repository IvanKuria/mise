import AppKit

extension NSScreen {
    /// The built-in (laptop) display, if any.
    static var builtIn: NSScreen? {
        screens.first { screen in
            guard let number = screen.deviceDescription[.init("NSScreenNumber")] as? NSNumber else { return false }
            return CGDisplayIsBuiltin(CGDirectDisplayID(number.uint32Value)) != 0
        }
    }

    /// The physical notch size on this screen, or `.zero` when there's no notch.
    /// Derived from public APIs only (`safeAreaInsets` + auxiliary top areas).
    var notchSize: CGSize {
        guard safeAreaInsets.top > 0 else { return .zero }
        let height = safeAreaInsets.top
        let left = auxiliaryTopLeftArea?.width ?? 0
        let right = auxiliaryTopRightArea?.width ?? 0
        let width = frame.width - left - right
        guard width > 0 else { return .zero }
        return CGSize(width: width, height: height)
    }

    var hasNotch: Bool { notchSize != .zero }
}

/// Resolves the screen the notch UI should live on, and the collapsed notch
/// geometry — using the real notch when present, or a faux notch (a small pill
/// centered under the menu bar) on Macs without one.
struct NotchPlacement {
    let screen: NSScreen
    /// Collapsed size of the notch surface (real notch, or faux pill).
    let notchSize: CGSize
    /// Whether this is a real hardware notch (vs a faux pill).
    let isRealNotch: Bool

    /// Faux-notch dimensions for non-notch Macs.
    static let fauxNotchSize = CGSize(width: 220, height: 32)

    static func resolve() -> NotchPlacement {
        if let builtIn = NSScreen.builtIn, builtIn.hasNotch {
            return NotchPlacement(screen: builtIn, notchSize: builtIn.notchSize, isRealNotch: true)
        }
        let screen = NSScreen.builtIn ?? NSScreen.main ?? NSScreen.screens.first!
        return NotchPlacement(screen: screen, notchSize: fauxNotchSize, isRealNotch: false)
    }

    /// The collapsed window frame (top-centered on the screen).
    var collapsedFrame: NSRect {
        rect(size: notchSize)
    }

    /// The expanded window frame for a given opened panel size; the panel hangs
    /// below the notch, so window height = notch height + opened height.
    func expandedFrame(openedSize: CGSize) -> NSRect {
        let width = max(openedSize.width, notchSize.width)
        let height = notchSize.height + openedSize.height
        return rect(size: CGSize(width: width, height: height))
    }

    /// A top-centered rect of `size` anchored to the top edge of the screen.
    private func rect(size: CGSize) -> NSRect {
        let f = screen.frame
        let x = f.midX - size.width / 2
        let y = f.maxY - size.height
        return NSRect(x: x, y: y, width: size.width, height: size.height)
    }
}
