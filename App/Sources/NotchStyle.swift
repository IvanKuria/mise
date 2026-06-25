import SwiftUI

/// The notch's tiny dark design system. The notch is physically black, so the
/// whole surface is dark; color is held back to posters, the Letterboxd-green
/// contribution scale, and one warm accent.
enum NotchStyle {
    // Surfaces (on black)
    static let panel = Color.black
    static let surface = Color.white.opacity(0.06)
    static let surfaceElevated = Color.white.opacity(0.10)
    static let hairline = Color.white.opacity(0.10)

    // Text
    static let textPrimary = Color.white.opacity(0.95)
    static let textSecondary = Color.white.opacity(0.60)
    static let textTertiary = Color.white.opacity(0.38)

    // Accents (Letterboxd palette)
    static let accent = Color(red: 1.0, green: 0.50, blue: 0.0)      // Letterboxd orange #FF8000
    static let green = Color(red: 0.0, green: 0.878, blue: 0.330)    // #00E054
    static let blue = Color(red: 0.251, green: 0.737, blue: 0.957)   // #40BCF4
    static let heartRed = Color(red: 0.93, green: 0.27, blue: 0.32)

    // Metrics
    static let panelCornerRadius: CGFloat = 22
    static let cardCornerRadius: CGFloat = 10
    static let spacing: CGFloat = 10

    /// GitHub-style contribution intensity (0 = empty … 4 = busiest), Letterboxd green.
    static func heatColor(level: Int) -> Color {
        switch max(0, min(4, level)) {
        case 0: return Color.white.opacity(0.07)
        case 1: return green.opacity(0.30)
        case 2: return green.opacity(0.55)
        case 3: return green.opacity(0.78)
        default: return green
        }
    }
}
