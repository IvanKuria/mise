import SwiftUI
import AppKit

/// A translucent vibrancy background that samples the desktop behind the window
/// (`.behindWindow`). This is what gives the app its soft, premium chrome — and
/// what tints it with whatever wallpaper sits behind it.
public struct VisualEffectBackground: NSViewRepresentable {
    public var material: NSVisualEffectView.Material
    public var blendingMode: NSVisualEffectView.BlendingMode
    public var isEmphasized: Bool

    public init(
        material: NSVisualEffectView.Material = .underWindowBackground,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        isEmphasized: Bool = false
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.isEmphasized = isEmphasized
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.isEmphasized = isEmphasized
        return view
    }

    public func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.material = material
        view.blendingMode = blendingMode
        view.isEmphasized = isEmphasized
    }
}

public extension View {
    /// Places a translucent vibrancy layer behind this view and lets it extend
    /// under the title bar — the app's base chrome.
    func miseWindowChrome(
        material: NSVisualEffectView.Material = .underWindowBackground
    ) -> some View {
        background(VisualEffectBackground(material: material).ignoresSafeArea())
    }
}
