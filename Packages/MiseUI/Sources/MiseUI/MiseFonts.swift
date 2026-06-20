import Foundation
import CoreText

/// Registers the bundled Repertory typefaces (Fraunces, Newsreader, Courier
/// Prime) with Core Text exactly once, so `Font.custom(...)` can resolve them.
/// `MiseTheme.init` touches `registerOnce` to guarantee registration before any
/// font is requested.
enum MiseFontRegistry {
    /// Family names used by `MiseTheme.font(_:)`.
    static let displayFamily = "Fraunces"
    static let bodyFamily = "Newsreader"
    static let dataFamily = "Courier Prime"

    static let registerOnce: Void = {
        let files = [
            ("Fraunces", "ttf"),
            ("Fraunces-Italic", "ttf"),
            ("Newsreader", "ttf"),
            ("CourierPrime-Regular", "ttf"),
            ("CourierPrime-Bold", "ttf"),
            ("CourierPrime-Italic", "ttf"),
        ]
        for (name, ext) in files {
            guard let url = Bundle.module.url(
                forResource: name, withExtension: ext, subdirectory: "Fonts"
            ) else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }()
}
