import Foundation
import Testing
@testable import ThemeKit

@Suite("Built-in presets")
struct PresetTests {
    @Test("provides at least four built-in themes")
    func count() {
        #expect(Theme.allBuiltIn.count >= 4)
    }

    @Test("includes the named presets")
    func namedPresets() {
        let names = Set(Theme.allBuiltIn.map(\.name))
        #expect(names.contains("Noir"))
        #expect(names.contains("Technicolor"))
        #expect(names.contains("Criterion"))
        #expect(names.contains("Terminal"))
    }

    @Test("all preset ids are unique and non-empty")
    func uniqueIDs() {
        let ids = Theme.allBuiltIn.map(\.id)
        #expect(ids.allSatisfy { !$0.isEmpty })
        #expect(Set(ids).count == ids.count)
    }

    @Test("all preset names are non-empty")
    func names() {
        #expect(Theme.allBuiltIn.allSatisfy { !$0.name.isEmpty })
    }

    @Test("every preset color has in-range components")
    func validColors() {
        for theme in Theme.allBuiltIn {
            for c in theme.palette.allColors {
                #expect((0.0...1.0).contains(c.red))
                #expect((0.0...1.0).contains(c.green))
                #expect((0.0...1.0).contains(c.blue))
                #expect((0.0...1.0).contains(c.alpha))
            }
        }
    }

    @Test("every preset has a positive size scale")
    func sizeScale() {
        #expect(Theme.allBuiltIn.allSatisfy { $0.typography.sizeScale > 0 })
    }

    @Test("named static constants are part of allBuiltIn")
    func staticConstants() {
        #expect(Theme.allBuiltIn.contains(Theme.noir))
        #expect(Theme.allBuiltIn.contains(Theme.technicolor))
        #expect(Theme.allBuiltIn.contains(Theme.criterion))
        #expect(Theme.allBuiltIn.contains(Theme.terminal))
    }
}
