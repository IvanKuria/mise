import Testing
import SwiftUI
import ThemeKit
@testable import ThemeStudioFeature

@MainActor
struct ThemeStudioModelTests {

    // MARK: Presets

    @Test func applyPresetReplacesWorkingTheme() {
        let model = ThemeStudioModel(theme: .noir)
        #expect(model.theme.id == Theme.noir.id)

        model.applyPreset(.technicolor)
        #expect(model.theme.id == Theme.technicolor.id)
        #expect(model.theme.palette.accent == Theme.technicolor.palette.accent)
        #expect(model.theme.posterWallStyle == Theme.technicolor.posterWallStyle)
    }

    @Test func presetsAreTheBuiltIns() {
        let model = ThemeStudioModel()
        #expect(model.presets.map(\.id) == Theme.allBuiltIn.map(\.id))
    }

    // MARK: PaletteRole get/set

    @Test func paletteRoleSettingPreservesOtherRoles() {
        let palette = Theme.noir.palette
        let newColor = RGBAColor(hex: "#123456FF")!
        let updated = PaletteRole.accent.setting(newColor, in: palette)

        #expect(PaletteRole.accent.color(in: updated) == newColor)
        // Every other role is untouched.
        for role in PaletteRole.allCases where role != .accent {
            #expect(role.color(in: updated) == role.color(in: palette))
        }
    }

    // MARK: Color <-> hex bridging

    @Test func setHexUpdatesRoleAndRoundTrips() {
        let model = ThemeStudioModel(theme: .noir)
        let ok = model.setHex("#FF8800FF", for: .accent)
        #expect(ok)
        #expect(model.hex(for: .accent) == "#FF8800FF")
    }

    @Test func setHexRejectsMalformedInputAndLeavesThemeUntouched() {
        let model = ThemeStudioModel(theme: .noir)
        let before = model.hex(for: .accent)
        let ok = model.setHex("not-a-color", for: .accent)
        #expect(!ok)
        #expect(model.hex(for: .accent) == before)
    }

    @Test func colorToRGBARoundTripsThroughHex() {
        // Build a Color from a known RGBA, bridge it back, and confirm the hex
        // string survives the SwiftUI Color <-> RGBAColor round trip.
        let original = RGBAColor(hex: "#3366CCFF")!
        let swiftColor = original.swiftUIColor
        let back = ThemeStudioModel.rgba(from: swiftColor)
        #expect(back.hexString == original.hexString)
    }

    @Test func setColorThenReadColorIsConsistent() {
        let model = ThemeStudioModel(theme: .criterion)
        let target = RGBAColor(hex: "#0A0B0CFF")!
        model.setColor(target.swiftUIColor, for: .surface)
        #expect(model.hex(for: .surface) == target.hexString)
    }

    // MARK: Typography & layout

    @Test func sizeScaleIsClamped() {
        let model = ThemeStudioModel()
        model.setSizeScale(99)
        #expect(model.theme.typography.sizeScale == ThemeStudioModel.sizeScaleRange.upperBound)
        model.setSizeScale(-5)
        #expect(model.theme.typography.sizeScale == ThemeStudioModel.sizeScaleRange.lowerBound)
        model.setSizeScale(1.1)
        #expect(model.theme.typography.sizeScale == 1.1)
    }

    @Test func settersUpdateTypographyAndLayout() {
        let model = ThemeStudioModel(theme: .noir)
        model.setFontFamily(.monospace)
        model.setLayoutDensity(.comfortable)
        model.setPosterWallStyle(.shelf)
        model.setWidgetSkin(.filmstrip)

        #expect(model.theme.typography.family == .monospace)
        #expect(model.theme.layoutDensity == .comfortable)
        #expect(model.theme.posterWallStyle == .shelf)
        #expect(model.theme.widgetSkin == .filmstrip)
    }

    // MARK: Export / Import round trip

    @Test func exportThenImportRoundTripsViaThemeKit() throws {
        let model = ThemeStudioModel(theme: .technicolor)
        model.setHex("#01020304", for: .background)
        model.setSizeScale(1.25)
        let expected = model.theme

        let data = try model.exportData()

        let other = ThemeStudioModel(theme: .noir)
        let ok = other.importData(data)
        #expect(ok)
        #expect(other.importError == nil)
        #expect(other.theme == expected)
    }

    @Test func exportProducesDecodableThemeDocument() throws {
        let model = ThemeStudioModel(theme: .criterion)
        let data = try model.exportData()
        let document = try ThemeDocument(data: data)
        #expect(document.schemaVersion == ThemeDocument.currentSchemaVersion)
        #expect(document.theme == .criterion)
    }

    // MARK: Import errors surfaced

    @Test func importMalformedDataSurfacesError() {
        let model = ThemeStudioModel(theme: .noir)
        let before = model.theme
        let ok = model.importData(Data("definitely not json".utf8))
        #expect(!ok)
        #expect(model.importError == .malformedData)
        // Working theme is left untouched on failure.
        #expect(model.theme == before)
    }

    @Test func importUnsupportedSchemaVersionSurfacesError() throws {
        // Round trip a real document then mutate its schema version to a future one.
        let valid = try ThemeStudioModel(theme: .noir).exportData()
        var object = try #require(
            try JSONSerialization.jsonObject(with: valid) as? [String: Any]
        )
        object["schemaVersion"] = 999
        let mutated = try JSONSerialization.data(withJSONObject: object)

        let model = ThemeStudioModel(theme: .terminal)
        let ok = model.importData(mutated)
        #expect(!ok)
        #expect(model.importError == .unsupportedSchemaVersion(999))
    }

    @Test func successfulImportClearsPriorError() throws {
        let model = ThemeStudioModel(theme: .noir)
        _ = model.importData(Data("bad".utf8))
        #expect(model.importError != nil)

        let good = try ThemeStudioModel(theme: .criterion).exportData()
        let ok = model.importData(good)
        #expect(ok)
        #expect(model.importError == nil)
        #expect(model.theme == .criterion)
    }
}
