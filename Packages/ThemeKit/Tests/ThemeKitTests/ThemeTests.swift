import Foundation
import Testing
@testable import ThemeKit

@Suite("Theme")
struct ThemeTests {
    private func sampleColor(_ hex: String) -> RGBAColor {
        RGBAColor(hex: hex)!
    }

    private func makeTheme() -> Theme {
        Theme(
            id: "test.theme",
            name: "Test",
            palette: Palette(
                background: sampleColor("#000000"),
                surface: sampleColor("#111111"),
                primaryText: sampleColor("#FFFFFF"),
                secondaryText: sampleColor("#AAAAAA"),
                accent: sampleColor("#FF0000"),
                secondaryAccent: sampleColor("#00FF00"),
                posterBorder: sampleColor("#222222"),
                posterShadow: sampleColor("#00000080")
            ),
            typography: Typography(family: .serif, sizeScale: 1.1),
            layoutDensity: .comfortable,
            posterWallStyle: .justified,
            widgetSkin: .minimal
        )
    }

    @Test("constructs and exposes its parts")
    func construct() {
        let t = makeTheme()
        #expect(t.id == "test.theme")
        #expect(t.name == "Test")
        #expect(t.palette.accent == sampleColor("#FF0000"))
        #expect(t.typography.family == .serif)
        #expect(t.typography.sizeScale == 1.1)
        #expect(t.layoutDensity == .comfortable)
        #expect(t.posterWallStyle == .justified)
        #expect(t.widgetSkin == .minimal)
    }

    @Test("is Hashable")
    func hashable() {
        let a = makeTheme()
        let b = makeTheme()
        #expect(a == b)
        #expect(Set([a, b]).count == 1)
    }

    @Test("round-trips through Codable")
    func codable() throws {
        let t = makeTheme()
        let data = try JSONEncoder().encode(t)
        let back = try JSONDecoder().decode(Theme.self, from: data)
        #expect(t == back)
    }

    @Test("enums cover all expected cases")
    func enumCases() {
        #expect(Set(LayoutDensity.allCases) == [.compact, .standard, .comfortable])
        #expect(PosterWallStyle.allCases.count == 4)
        #expect(Set(PosterWallStyle.allCases) == [.grid, .justified, .shelf, .wall])
        #expect(!WidgetSkin.allCases.isEmpty)
        #expect(!FontFamily.allCases.isEmpty)
    }
}
