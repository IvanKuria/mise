import Testing
import SwiftUI
import ThemeKit
@testable import MiseUI

@Suite("RGBAColor -> SwiftUI Color bridge")
struct ColorBridgeTests {

    /// Round-trips an RGBAColor through SwiftUI.Color and back to components,
    /// verifying the bridge preserves values within float tolerance.
    @Test("round-trips components through Color")
    func roundTrip() throws {
        let original = RGBAColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 0.8)
        let color = original.swiftUIColor
        let resolved = color.resolve(in: EnvironmentValues())

        #expect(abs(Double(resolved.red) - original.red) < 0.01)
        #expect(abs(Double(resolved.green) - original.green) < 0.01)
        #expect(abs(Double(resolved.blue) - original.blue) < 0.01)
        #expect(abs(Double(resolved.opacity) - original.alpha) < 0.01)
    }

    @Test("preserves pure white and black")
    func extremes() {
        let white = RGBAColor(red: 1, green: 1, blue: 1).swiftUIColor.resolve(in: EnvironmentValues())
        #expect(white.red > 0.99 && white.green > 0.99 && white.blue > 0.99)

        let black = RGBAColor(red: 0, green: 0, blue: 0).swiftUIColor.resolve(in: EnvironmentValues())
        #expect(black.red < 0.01 && black.green < 0.01 && black.blue < 0.01)
    }
}

@Suite("MiseTheme resolution from presets")
struct MiseThemeResolutionTests {

    @Test("resolves every built-in preset's colors to match its palette", arguments: Theme.allBuiltIn)
    func resolvesPalette(theme: Theme) {
        let mise = MiseTheme(theme)
        let env = EnvironmentValues()

        func same(_ a: Color, _ b: RGBAColor) -> Bool {
            let r = a.resolve(in: env)
            return abs(Double(r.red) - b.red) < 0.01
                && abs(Double(r.green) - b.green) < 0.01
                && abs(Double(r.blue) - b.blue) < 0.01
        }

        #expect(same(mise.background, theme.palette.background))
        #expect(same(mise.surface, theme.palette.surface))
        #expect(same(mise.primaryText, theme.palette.primaryText))
        #expect(same(mise.secondaryText, theme.palette.secondaryText))
        #expect(same(mise.accent, theme.palette.accent))
        #expect(same(mise.secondaryAccent, theme.palette.secondaryAccent))
        #expect(same(mise.posterBorder, theme.palette.posterBorder))
        #expect(same(mise.posterShadow, theme.palette.posterShadow))
    }

    @Test("default environment theme is Noir")
    func defaultIsNoir() {
        let env = EnvironmentValues()
        #expect(env.miseTheme.theme.id == Theme.noir.id)
    }
}

@Suite("FontRole + size scaling")
struct FontScalingTests {

    @Test("size scales linearly with the theme's sizeScale")
    func linearScaling() {
        let base = MiseTheme.scaledFontSize(role: .body, sizeScale: 1.0)
        let bigger = MiseTheme.scaledFontSize(role: .body, sizeScale: 2.0)
        #expect(base == FontRole.body.baseSize)
        #expect(bigger == FontRole.body.baseSize * 2)
    }

    @Test("size never drops below the 8pt floor")
    func floor() {
        let tiny = MiseTheme.scaledFontSize(role: .caption, sizeScale: 0.1)
        #expect(tiny >= 8)
    }

    @Test("type scale is strictly descending largeTitle > title > headline > body > caption")
    func descendingScale() {
        let order: [FontRole] = [.largeTitle, .title, .headline, .body, .caption]
        let sizes = order.map(\.baseSize)
        #expect(sizes == sizes.sorted(by: >))
    }

    @Test("mono role always maps to monospaced design regardless of family", arguments: FontFamily.allCases)
    func monoAlwaysMonospaced(family: FontFamily) {
        #expect(MiseTheme.fontDesign(for: family, role: .mono) == .monospaced)
    }

    @Test("non-mono roles follow the family")
    func familyMapping() {
        #expect(MiseTheme.fontDesign(for: .serif, role: .body) == .serif)
        #expect(MiseTheme.fontDesign(for: .roundedSans, role: .body) == .rounded)
        #expect(MiseTheme.fontDesign(for: .monospace, role: .body) == .monospaced)
        #expect(MiseTheme.fontDesign(for: .system, role: .body) == .default)
        #expect(MiseTheme.fontDesign(for: .condensed, role: .body) == .default)
    }
}

@Suite("Spacing + corner radius density scaling")
struct DensityScalingTests {

    @Test("density scale orders compact < standard < comfortable")
    func ordering() {
        #expect(MiseTheme.densityScale(.compact) < MiseTheme.densityScale(.standard))
        #expect(MiseTheme.densityScale(.standard) < MiseTheme.densityScale(.comfortable))
    }

    @Test("spacing scales by base unit, steps, and density")
    func spacingMath() {
        let s = MiseTheme.spacing(steps: 2, density: .standard)
        #expect(s == MiseTheme.baseSpacingUnit * 2 * 1.0)

        let compact = MiseTheme.spacing(steps: 2, density: .compact)
        #expect(compact == MiseTheme.baseSpacingUnit * 2 * MiseTheme.densityScale(.compact))
    }

    @Test("corner radius scales with density")
    func cornerRadius() {
        let comfy = MiseTheme(Theme(
            id: "t", name: "t",
            palette: Theme.noir.palette,
            typography: Theme.noir.typography,
            layoutDensity: .comfortable,
            posterWallStyle: .grid,
            widgetSkin: .poster
        ))
        #expect(comfy.cornerRadius == MiseTheme.baseCornerRadius * MiseTheme.densityScale(.comfortable))
        #expect(comfy.smallCornerRadius < comfy.cornerRadius)
    }
}
