import Foundation

/// A SwiftUI-free, Codable RGBA color with components in the closed range `0...1`.
///
/// The app layer is responsible for mapping this into `SwiftUI.Color`; ThemeKit
/// stays free of UI frameworks so it remains unit-testable on the command line.
public struct RGBAColor: Codable, Hashable, Sendable {
    /// Red component, clamped to `0...1`.
    public let red: Double
    /// Green component, clamped to `0...1`.
    public let green: Double
    /// Blue component, clamped to `0...1`.
    public let blue: Double
    /// Alpha component, clamped to `0...1`.
    public let alpha: Double

    /// Creates a color from raw components. Values outside `0...1` are clamped.
    public init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = RGBAColor.clamp(red)
        self.green = RGBAColor.clamp(green)
        self.blue = RGBAColor.clamp(blue)
        self.alpha = RGBAColor.clamp(alpha)
    }

    /// Creates a color from a hex string.
    ///
    /// Accepts `"#RRGGBB"` or `"#RRGGBBAA"`, case-insensitively, with an optional
    /// leading `#`. Returns `nil` for any malformed input.
    public init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }

        guard s.count == 6 || s.count == 8 else { return nil }
        guard s.allSatisfy(\.isHexDigit) else { return nil }
        guard let value = UInt64(s, radix: 16) else { return nil }

        let r, g, b, a: Double
        if s.count == 8 {
            r = Double((value >> 24) & 0xFF) / 255.0
            g = Double((value >> 16) & 0xFF) / 255.0
            b = Double((value >> 8) & 0xFF) / 255.0
            a = Double(value & 0xFF) / 255.0
        } else {
            r = Double((value >> 16) & 0xFF) / 255.0
            g = Double((value >> 8) & 0xFF) / 255.0
            b = Double(value & 0xFF) / 255.0
            a = 1.0
        }
        self.init(red: r, green: g, blue: b, alpha: a)
    }

    /// The color rendered as an uppercase `"#RRGGBBAA"` string.
    public var hexString: String {
        func byte(_ c: Double) -> Int { Int((c * 255.0).rounded()) }
        return String(
            format: "#%02X%02X%02X%02X",
            byte(red), byte(green), byte(blue), byte(alpha)
        )
    }

    private static func clamp(_ v: Double) -> Double {
        Swift.min(1.0, Swift.max(0.0, v))
    }
}
