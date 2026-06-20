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

    // MARK: Typography

    /// The resolved, size-scaled font for a semantic role, honoring the theme's
    /// `FontFamily`. The `.mono` role is always monospaced regardless of family.
    public func font(_ role: FontRole) -> Font {
        let size = MiseTheme.scaledFontSize(role: role, sizeScale: theme.typography.sizeScale)
        let design = MiseTheme.fontDesign(for: theme.typography.family, role: role)
        return Font.system(size: size, weight: role.weight, design: design)
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
    /// Base corner radius (pre-density).
    public static let baseCornerRadius: CGFloat = 10

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
