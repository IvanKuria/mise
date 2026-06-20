import SwiftUI
import ThemeKit

public extension RGBAColor {
    /// The color expressed as a SwiftUI `Color`, preserving the `0...1` RGBA
    /// components in the (extended) sRGB color space.
    var swiftUIColor: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}
