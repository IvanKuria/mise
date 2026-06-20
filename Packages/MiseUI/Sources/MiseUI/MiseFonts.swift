import Foundation
import CoreText

/// Registers the bundled typefaces (Bricolage Grotesque, Geist, Geist Mono) with
/// Core Text exactly once, so `Font.custom(...)` can resolve them. `MiseTheme.init`
/// touches `registerOnce` to guarantee registration before any font is requested.
enum MiseFontRegistry {
    /// Family names used by `MiseTheme.font(_:)`.
    static let displayFamily = "Bricolage Grotesque"
    static let bodyFamily = "Geist"
    static let dataFamily = "Geist Mono"

    static let registerOnce: Void = {
        let files = [
            ("BricolageGrotesque", "ttf"),
            ("Geist", "ttf"),
            ("GeistMono", "ttf"),
        ]
        for (name, ext) in files {
            guard let url = Bundle.module.url(
                forResource: name, withExtension: ext, subdirectory: "Fonts"
            ) else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }()
}
