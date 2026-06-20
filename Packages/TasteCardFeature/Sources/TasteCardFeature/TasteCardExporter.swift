import SwiftUI
import ThemeKit
import TasteProfile

#if canImport(AppKit)
import AppKit
#endif

/// Rasterizes a `TasteCardView` to PNG data for sharing / saving, using SwiftUI's
/// `ImageRenderer`. Pure rendering: no disk I/O, returns the encoded bytes.
public struct TasteCardExporter {

    public init() {}

    /// Renders the card for `profile` with `theme` at the requested point `size`,
    /// at the given `scale` (e.g. 2.0 for retina-quality output), and returns PNG
    /// bytes. Returns `nil` if rendering or PNG encoding fails.
    ///
    /// Must run on the main actor: `ImageRenderer` touches the SwiftUI/AppKit
    /// rendering stack.
    @MainActor
    public func pngData(
        for profile: TasteProfile,
        theme: Theme,
        size: CGSize,
        scale: CGFloat = 2.0
    ) -> Data? {
        let variant: TasteCardVariant = size.height > size.width * 1.2 ? .portrait : .square

        let card = TasteCardView(profile: profile, variant: variant)
            .miseTheme(theme)
            .frame(width: size.width, height: size.height)

        let renderer = ImageRenderer(content: card)
        renderer.scale = scale
        renderer.isOpaque = true
        return Self.encodePNG(from: renderer)
    }

    /// Pulls a PNG out of an `ImageRenderer` across platforms. Factored out so the
    /// platform-specific bridging lives in one place.
    @MainActor
    static func encodePNG(from renderer: ImageRenderer<some View>) -> Data? {
        #if canImport(AppKit)
        guard let cgImage = renderer.cgImage else { return nil }
        let rep = NSBitmapImageRep(cgImage: cgImage)
        return rep.representation(using: .png, properties: [:])
        #else
        return nil
        #endif
    }
}
