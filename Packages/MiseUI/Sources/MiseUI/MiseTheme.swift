import SwiftUI
import ThemeKit

/// A semantic typography role. Each role maps to a base point size that is then
/// scaled by the active `Theme`'s `Typography.sizeScale`.
public enum FontRole: Sendable, CaseIterable {
    case largeTitle
    case title
    case headline
    case body
    case caption
    case mono

    /// The unscaled base point size for this role.
    public var baseSize: CGFloat {
        switch self {
        case .largeTitle: return 34
        case .title:      return 24
        case .headline:   return 18
        case .body:       return 14
        case .caption:    return 11
        case .mono:       return 13
        }
    }

    /// The base weight for this role.
    public var weight: Font.Weight {
        switch self {
        case .largeTitle: return .bold
        case .title:      return .semibold
        case .headline:   return .semibold
        case .body:       return .regular
        case .caption:    return .regular
        case .mono:       return .regular
        }
    }
}

/// A fully-resolved, SwiftUI-ready view of a `ThemeKit.Theme`: concrete colors,
/// fonts, and density-scaled metrics. Downstream views read this from the
/// environment via `@Environment(\.miseTheme)`.
public struct MiseTheme: Sendable, Equatable {
    /// The underlying ThemeKit theme this was resolved from.
    public let theme: Theme

    public init(_ theme: Theme) {
        // Ensure the bundled Repertory typefaces are registered before use.
        _ = MiseFontRegistry.registerOnce
        self.theme = theme
    }

    // MARK: Colors

    public var background: Color { theme.palette.background.swiftUIColor }
    public var surface: Color { theme.palette.surface.swiftUIColor }
    public var primaryText: Color { theme.palette.primaryText.swiftUIColor }
    public var secondaryText: Color { theme.palette.secondaryText.swiftUIColor }
    public var accent: Color { theme.palette.accent.swiftUIColor }
    public var secondaryAccent: Color { theme.palette.secondaryAccent.swiftUIColor }
    public var posterBorder: Color { theme.palette.posterBorder.swiftUIColor }
    public var posterShadow: Color { theme.palette.posterShadow.swiftUIColor }

    // MARK: Semantic tokens (translucent, premium chrome)

    /// Whether the active palette reads as dark (drives ink color for the
    /// opacity-based token system below).
    public var isDark: Bool { MiseTheme.luminance(theme.palette.background) < 0.5 }

    /// The base "ink" the opacity tokens are built from: white on dark, near-black on light.
    private var ink: Color { isDark ? .white : .black }

    /// Text at three levels of emphasis (opacity-based, like the reference).
    public var textPrimary: Color { ink.opacity(0.93) }
    public var textSecondary: Color { ink.opacity(0.58) }
    public var textTertiary: Color { ink.opacity(0.38) }

    /// Elevated translucent surface fill for cards/panels over the vibrancy.
    public var cardFill: Color { ink.opacity(isDark ? 0.06 : 0.05) }
    /// A slightly stronger fill for nested/hovered surfaces.
    public var cardFillStrong: Color { ink.opacity(isDark ? 0.10 : 0.08) }
    /// Hairline stroke for separating translucent surfaces.
    public var hairline: Color { ink.opacity(isDark ? 0.10 : 0.10) }
    /// Recessed wells (inputs, tracks).
    public var recess: Color { ink.opacity(isDark ? 0.14 : 0.06) }

    /// Subtle fill shown on hover.
    public var hoverFill: Color { ink.opacity(0.06) }
    /// The selected-row pill fill (bright, like the reference's white pill).
    public var selectionFill: Color { isDark ? Color.white.opacity(0.95) : Color.black.opacity(0.90) }
    /// Text/icon color on top of `selectionFill`.
    public var onSelection: Color { isDark ? Color.black.opacity(0.9) : Color.white.opacity(0.95) }

    /// Soft elevation shadow for cards (color, radius, y-offset).
    public var shadowColor: Color { Color.black.opacity(isDark ? 0.45 : 0.14) }
    public var shadowRadius: CGFloat { 24 }
    public var shadowY: CGFloat { 14 }

    /// Standard interaction motion: a gentle spring for selection/appearance.
    public var motion: Animation { .spring(response: 0.32, dampingFraction: 0.82) }
    /// Fast ease for hover fills.
    public var hoverMotion: Animation { .easeOut(duration: 0.14) }

    /// Pure: relative luminance (0...1) of an RGBAColor, for dark/light detection.
    public static func luminance(_ c: RGBAColor) -> Double {
        0.2126 * c.red + 0.7152 * c.green + 0.0722 * c.blue
    }

    // MARK: Typography

    /// The resolved, size-scaled font for a semantic role. Uses SF Pro (the
    /// system face) with deliberate weights and optical sizing — the premium
    /// feel comes from the hierarchy, spacing, and opacity system, not a novelty
    /// typeface (per the macOS HIG / Linear-Arc-Raycast register).
    public func font(_ role: FontRole) -> Font {
        let size = MiseTheme.scaledFontSize(role: role, sizeScale: theme.typography.sizeScale)
        switch role {
        case .largeTitle:
            return .system(size: size, weight: .bold, design: .default)
        case .title:
            return .system(size: size, weight: .semibold, design: .default)
        case .headline:
            return .system(size: size, weight: .semibold, design: .default)
        case .body:
            return .system(size: size, weight: .regular, design: .default)
        case .caption:
            return .system(size: size, weight: .medium, design: .default)
        case .mono:
            return .system(size: size, weight: .regular, design: .monospaced)
        }
    }

    /// Pure: the point size for a role at a given size scale, clamped to a sane
    /// minimum so text never collapses.
    public static func scaledFontSize(role: FontRole, sizeScale: Double) -> CGFloat {
        let scaled = role.baseSize * CGFloat(sizeScale)
        return max(8, scaled)
    }

    /// Pure: maps a `FontFamily` (and role) to a SwiftUI `Font.Design`.
    public static func fontDesign(for family: FontFamily, role: FontRole) -> Font.Design {
        if role == .mono { return .monospaced }
        switch family {
        case .system:      return .default
        case .serif:       return .serif
        case .roundedSans: return .rounded
        case .monospace:   return .monospaced
        case .condensed:   return .default
        }
    }

    // MARK: Metrics

    /// Density multiplier applied to spacing and corner radii.
    public static func densityScale(_ density: LayoutDensity) -> CGFloat {
        switch density {
        case .compact:     return 0.75
        case .standard:    return 1.0
        case .comfortable: return 1.3
        }
    }

    /// Base spacing unit (pre-density). The product's rhythm is built on this.
    public static let baseSpacingUnit: CGFloat = 8
    /// Base corner radius (pre-density). Generous, for soft rounded cards.
    public static let baseCornerRadius: CGFloat = 16

    /// Pure: a density-scaled spacing value for a step count (1 == base unit).
    public static func spacing(steps: CGFloat, density: LayoutDensity) -> CGFloat {
        baseSpacingUnit * steps * densityScale(density)
    }

    /// The active density scale.
    public var density: LayoutDensity { theme.layoutDensity }

    /// A density-scaled spacing value (1 step == base unit). Generous by design.
    public func spacing(_ steps: CGFloat = 1) -> CGFloat {
        MiseTheme.spacing(steps: steps, density: density)
    }

    /// The density-scaled corner radius used across surfaces and posters.
    public var cornerRadius: CGFloat {
        MiseTheme.baseCornerRadius * MiseTheme.densityScale(density)
    }

    /// A tighter corner radius for small chrome (chips, tags).
    public var smallCornerRadius: CGFloat {
        cornerRadius * 0.6
    }
}
