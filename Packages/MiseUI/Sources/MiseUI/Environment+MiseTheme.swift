import SwiftUI
import ThemeKit

private struct MiseThemeKey: EnvironmentKey {
    static let defaultValue = MiseTheme(.noir)
}

public extension EnvironmentValues {
    /// The active resolved theme. Defaults to `Theme.noir`.
    var miseTheme: MiseTheme {
        get { self[MiseThemeKey.self] }
        set { self[MiseThemeKey.self] = newValue }
    }
}

public extension View {
    /// Resolves and injects the given `ThemeKit.Theme` into the environment so all
    /// MiseUI components render with it.
    func miseTheme(_ theme: Theme) -> some View {
        environment(\.miseTheme, MiseTheme(theme))
    }
}
