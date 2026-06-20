import Foundation

/// A named set of colors used to render the app.
public struct Palette: Codable, Hashable, Sendable {
    public var background: RGBAColor
    public var surface: RGBAColor
    public var primaryText: RGBAColor
    public var secondaryText: RGBAColor
    public var accent: RGBAColor
    public var secondaryAccent: RGBAColor
    public var posterBorder: RGBAColor
    public var posterShadow: RGBAColor

    public init(
        background: RGBAColor,
        surface: RGBAColor,
        primaryText: RGBAColor,
        secondaryText: RGBAColor,
        accent: RGBAColor,
        secondaryAccent: RGBAColor,
        posterBorder: RGBAColor,
        posterShadow: RGBAColor
    ) {
        self.background = background
        self.surface = surface
        self.primaryText = primaryText
        self.secondaryText = secondaryText
        self.accent = accent
        self.secondaryAccent = secondaryAccent
        self.posterBorder = posterBorder
        self.posterShadow = posterShadow
    }

    /// All colors in the palette, useful for validation.
    public var allColors: [RGBAColor] {
        [background, surface, primaryText, secondaryText,
         accent, secondaryAccent, posterBorder, posterShadow]
    }
}

/// A font family / role choice. The app layer maps each case to a concrete font.
public enum FontFamily: String, Codable, Hashable, Sendable, CaseIterable {
    case system
    case serif
    case roundedSans
    case monospace
    case condensed
}

/// A typography choice: a font family plus a multiplicative size scale.
public struct Typography: Codable, Hashable, Sendable {
    public var family: FontFamily
    /// Multiplier applied to base font sizes (e.g. `1.0` = default).
    public var sizeScale: Double

    public init(family: FontFamily, sizeScale: Double) {
        self.family = family
        self.sizeScale = sizeScale
    }
}

/// How tightly packed app content is laid out.
public enum LayoutDensity: String, Codable, Hashable, Sendable, CaseIterable {
    case compact
    case standard
    case comfortable
}

/// How a wall of posters is arranged.
public enum PosterWallStyle: String, Codable, Hashable, Sendable, CaseIterable {
    case grid
    case justified
    case shelf
    case wall
}

/// The visual treatment applied to the home-screen widget.
public enum WidgetSkin: String, Codable, Hashable, Sendable, CaseIterable {
    case minimal
    case poster
    case filmstrip
    case stats
}

/// A full, shareable look: palette + typography + layout choices.
public struct Theme: Codable, Hashable, Sendable, Identifiable {
    /// A stable, unique identifier (used for equality of identity and lookups).
    public let id: String
    /// A human-readable display name.
    public let name: String
    public var palette: Palette
    public var typography: Typography
    public var layoutDensity: LayoutDensity
    public var posterWallStyle: PosterWallStyle
    public var widgetSkin: WidgetSkin

    public init(
        id: String,
        name: String,
        palette: Palette,
        typography: Typography,
        layoutDensity: LayoutDensity,
        posterWallStyle: PosterWallStyle,
        widgetSkin: WidgetSkin
    ) {
        self.id = id
        self.name = name
        self.palette = palette
        self.typography = typography
        self.layoutDensity = layoutDensity
        self.posterWallStyle = posterWallStyle
        self.widgetSkin = widgetSkin
    }
}
