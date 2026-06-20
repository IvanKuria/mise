import Foundation

extension Theme {
    /// Convenience for building preset palettes from known-good hex strings.
    /// Force-unwraps are safe here because the literals are compile-time constants
    /// validated by the preset test suite.
    private static func color(_ hex: String) -> RGBAColor {
        guard let c = RGBAColor(hex: hex) else {
            preconditionFailure("Invalid preset hex literal: \(hex)")
        }
        return c
    }

    /// Monochrome, high-contrast, cinema-dark.
    public static let noir = Theme(
        id: "builtin.noir",
        name: "Noir",
        palette: Palette(
            background: color("#0B0B0C"),
            surface: color("#161617"),
            primaryText: color("#F5F5F5"),
            secondaryText: color("#9A9A9C"),
            accent: color("#E8E8E8"),
            secondaryAccent: color("#6E6E70"),
            posterBorder: color("#2A2A2C"),
            posterShadow: color("#000000B3")
        ),
        typography: Typography(family: .serif, sizeScale: 1.0),
        layoutDensity: .standard,
        posterWallStyle: .grid,
        widgetSkin: .poster
    )

    /// Saturated, bold, candy-colored.
    public static let technicolor = Theme(
        id: "builtin.technicolor",
        name: "Technicolor",
        palette: Palette(
            background: color("#12022B"),
            surface: color("#22074A"),
            primaryText: color("#FFFFFF"),
            secondaryText: color("#C9A8FF"),
            accent: color("#FF2E97"),
            secondaryAccent: color("#22D3EE"),
            posterBorder: color("#FF8A00"),
            posterShadow: color("#FF2E9799")
        ),
        typography: Typography(family: .roundedSans, sizeScale: 1.05),
        layoutDensity: .comfortable,
        posterWallStyle: .wall,
        widgetSkin: .filmstrip
    )

    /// Clean, restrained, light editorial look.
    public static let criterion = Theme(
        id: "builtin.criterion",
        name: "Criterion",
        palette: Palette(
            background: color("#FBFAF7"),
            surface: color("#FFFFFF"),
            primaryText: color("#1A1A1A"),
            secondaryText: color("#6B6B6B"),
            accent: color("#1F4E8C"),
            secondaryAccent: color("#C0392B"),
            posterBorder: color("#E2DFD8"),
            posterShadow: color("#0000001A")
        ),
        typography: Typography(family: .serif, sizeScale: 1.0),
        layoutDensity: .standard,
        posterWallStyle: .justified,
        widgetSkin: .minimal
    )

    /// Green-on-black terminal ricing.
    public static let terminal = Theme(
        id: "builtin.terminal",
        name: "Terminal",
        palette: Palette(
            background: color("#000000"),
            surface: color("#0A140A"),
            primaryText: color("#33FF66"),
            secondaryText: color("#1F9E3D"),
            accent: color("#33FF66"),
            secondaryAccent: color("#A6FF00"),
            posterBorder: color("#0F3D17"),
            posterShadow: color("#33FF6640")
        ),
        typography: Typography(family: .monospace, sizeScale: 0.95),
        layoutDensity: .compact,
        posterWallStyle: .shelf,
        widgetSkin: .stats
    )

    /// Archival film-program look: warm film-stock paper, ink, oxblood + aged gold.
    /// The default identity — quiet, editorial, poster-forward.
    public static let repertory = Theme(
        id: "builtin.repertory",
        name: "Repertory",
        palette: Palette(
            background: color("#E4DFD2"),
            surface: color("#EFEBE0"),
            primaryText: color("#1A1714"),
            secondaryText: color("#6B6256"),
            accent: color("#7A1F2B"),
            secondaryAccent: color("#9C7A3C"),
            posterBorder: color("#1A1714"),
            posterShadow: color("#1A171426")
        ),
        typography: Typography(family: .serif, sizeScale: 1.0),
        layoutDensity: .standard,
        posterWallStyle: .justified,
        widgetSkin: .minimal
    )

    /// Cinematic dark chrome with warm marquee gold — quiet UI so posters carry
    /// the color. The default identity.
    public static let marquee = Theme(
        id: "builtin.marquee",
        name: "Marquee",
        palette: Palette(
            background: color("#20271A"),
            surface: color("#2C3524"),
            primaryText: color("#F2F1E6"),
            secondaryText: color("#A6AD94"),
            accent: color("#E8B45C"),
            secondaryAccent: color("#C5705A"),
            posterBorder: color("#3C4630"),
            posterShadow: color("#0B0F08AA")
        ),
        typography: Typography(family: .system, sizeScale: 1.0),
        layoutDensity: .comfortable,
        posterWallStyle: .grid,
        widgetSkin: .poster
    )

    /// Neutral, translucent premium chrome — the default. Reads as a soft dark
    /// vibrancy that picks up the desktop behind it; posters carry the color.
    public static let studio = Theme(
        id: "builtin.studio",
        name: "Studio",
        palette: Palette(
            background: color("#1B1C1E"),
            surface: color("#26272B"),
            primaryText: color("#FFFFFF"),
            secondaryText: color("#9C9CA2"),
            accent: color("#E0A75A"),
            secondaryAccent: color("#C5705A"),
            posterBorder: color("#FFFFFF1F"),
            posterShadow: color("#00000080")
        ),
        typography: Typography(family: .system, sizeScale: 1.0),
        layoutDensity: .standard,
        posterWallStyle: .grid,
        widgetSkin: .poster
    )

    /// All built-in presets, in display order.
    public static let allBuiltIn: [Theme] = [studio, marquee, repertory, noir, technicolor, criterion, terminal]
}
