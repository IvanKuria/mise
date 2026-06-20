import SwiftUI
import ThemeKit

/// Identifies one editable color slot in a ``Palette``. Used to drive a generic
/// list of color wells and to read/write individual roles without hand-writing a
/// switch at every call site.
public enum PaletteRole: String, CaseIterable, Sendable, Identifiable, Hashable {
    case background
    case surface
    case primaryText
    case secondaryText
    case accent
    case secondaryAccent
    case posterBorder
    case posterShadow

    public var id: String { rawValue }

    /// A human-readable label for the role.
    public var label: String {
        switch self {
        case .background:      return "Background"
        case .surface:         return "Surface"
        case .primaryText:     return "Primary Text"
        case .secondaryText:   return "Secondary Text"
        case .accent:          return "Accent"
        case .secondaryAccent: return "Secondary Accent"
        case .posterBorder:    return "Poster Border"
        case .posterShadow:    return "Poster Shadow"
        }
    }

    /// Reads this role's color out of a palette.
    public func color(in palette: Palette) -> RGBAColor {
        switch self {
        case .background:      return palette.background
        case .surface:         return palette.surface
        case .primaryText:     return palette.primaryText
        case .secondaryText:   return palette.secondaryText
        case .accent:          return palette.accent
        case .secondaryAccent: return palette.secondaryAccent
        case .posterBorder:    return palette.posterBorder
        case .posterShadow:    return palette.posterShadow
        }
    }

    /// Returns a copy of `palette` with this role set to `color`.
    public func setting(_ color: RGBAColor, in palette: Palette) -> Palette {
        var p = palette
        switch self {
        case .background:      p.background = color
        case .surface:         p.surface = color
        case .primaryText:     p.primaryText = color
        case .secondaryText:   p.secondaryText = color
        case .accent:          p.accent = color
        case .secondaryAccent: p.secondaryAccent = color
        case .posterBorder:    p.posterBorder = color
        case .posterShadow:    p.posterShadow = color
        }
        return p
    }
}

/// The "Theme Studio" working state: a mutable ``Theme`` plus the operations the
/// UI performs on it (apply a preset, edit colors, set typography/layout, and
/// export/import a shareable `.misetheme` document).
///
/// All non-trivial logic is exposed as pure `static` functions so it is unit
/// testable without constructing the `@MainActor` model.
@MainActor
@Observable
public final class ThemeStudioModel {

    /// The theme currently being edited. The live preview renders from this.
    public var theme: Theme

    /// The most recent import error, surfaced for the UI to display. Cleared on a
    /// successful import or a fresh attempt.
    public var importError: ThemeDocumentError?

    /// Creates a studio seeded with a starting theme (defaults to ``Theme/noir``).
    public init(theme: Theme = .noir) {
        self.theme = theme
        self.importError = nil
    }

    // MARK: Presets

    /// The built-in presets available to apply, in display order.
    public var presets: [Theme] { Theme.allBuiltIn }

    /// Replaces the working theme with a built-in preset.
    public func applyPreset(_ preset: Theme) {
        theme = preset
    }

    // MARK: Color editing

    /// The current color for a palette role, as a SwiftUI `Color`.
    public func color(for role: PaletteRole) -> Color {
        role.color(in: theme.palette).swiftUIColor
    }

    /// Sets a palette role from a SwiftUI `Color`, bridging through hex so the
    /// stored value is a clean ``RGBAColor``.
    public func setColor(_ color: Color, for role: PaletteRole) {
        let rgba = Self.rgba(from: color)
        theme.palette = role.setting(rgba, in: theme.palette)
    }

    /// The current color for a palette role as an uppercase `#RRGGBBAA` string.
    public func hex(for role: PaletteRole) -> String {
        role.color(in: theme.palette).hexString
    }

    /// Sets a palette role from a hex string. Ignores malformed input.
    /// - Returns: `true` if the hex was valid and applied, `false` otherwise.
    @discardableResult
    public func setHex(_ hex: String, for role: PaletteRole) -> Bool {
        guard let rgba = RGBAColor(hex: hex) else { return false }
        theme.palette = role.setting(rgba, in: theme.palette)
        return true
    }

    // MARK: Typography & layout

    /// Sets the font family.
    public func setFontFamily(_ family: FontFamily) {
        theme.typography.family = family
    }

    /// Sets the font size scale, clamped to a sane range so the preview never
    /// collapses or explodes.
    public func setSizeScale(_ scale: Double) {
        theme.typography.sizeScale = Self.clampSizeScale(scale)
    }

    /// Sets the layout density.
    public func setLayoutDensity(_ density: LayoutDensity) {
        theme.layoutDensity = density
    }

    /// Sets the poster-wall style.
    public func setPosterWallStyle(_ style: PosterWallStyle) {
        theme.posterWallStyle = style
    }

    /// Sets the widget skin.
    public func setWidgetSkin(_ skin: WidgetSkin) {
        theme.widgetSkin = skin
    }

    // MARK: Export / Import

    /// Encodes the working theme to a shareable `.misetheme` document.
    public func exportData() throws -> Data {
        try ThemeDocument(theme: theme).data()
    }

    /// Replaces the working theme from a `.misetheme` document.
    ///
    /// On failure the working theme is left untouched and ``importError`` is set
    /// to the surfaced ``ThemeDocumentError``.
    /// - Returns: `true` on success, `false` if the import failed.
    @discardableResult
    public func importData(_ data: Data) -> Bool {
        importError = nil
        do {
            let document = try ThemeDocument(data: data)
            theme = document.theme
            return true
        } catch let error as ThemeDocumentError {
            importError = error
            return false
        } catch {
            importError = .malformedData
            return false
        }
    }

    // MARK: Pure helpers

    /// The valid range for the font size scale.
    public static let sizeScaleRange: ClosedRange<Double> = 0.7...1.6

    /// Clamps a size scale into ``sizeScaleRange``.
    public static func clampSizeScale(_ scale: Double) -> Double {
        min(sizeScaleRange.upperBound, max(sizeScaleRange.lowerBound, scale))
    }

    /// Bridges a SwiftUI `Color` to an ``RGBAColor`` via the platform resolver,
    /// so a round-trip through the studio yields clean `0...1` components.
    public static func rgba(from color: Color) -> RGBAColor {
        let resolved = color.resolve(in: EnvironmentValues())
        return RGBAColor(
            red: Double(resolved.red),
            green: Double(resolved.green),
            blue: Double(resolved.blue),
            alpha: Double(resolved.opacity)
        )
    }
}
