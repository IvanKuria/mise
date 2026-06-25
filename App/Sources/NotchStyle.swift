import SwiftUI

/// The notch's design tokens. The notch is physically black, so the surface is
/// pure black with near-monochrome content — color is held back to poster art,
/// a soft gold for stars, and a muted green for the activity grid. Tuned to read
/// as a first-party Apple surface (Dynamic Island register).
enum NotchStyle {
    // Surface
    static let panel = Color.black
    static let surface = Color.white.opacity(0.07)
    static let surfaceElevated = Color.white.opacity(0.12)
    static let hairline = Color.white.opacity(0.08)

    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.55)
    static let textTertiary = Color.white.opacity(0.32)

    // Restrained color
    static let star = Color(red: 0.98, green: 0.78, blue: 0.38)
    static let heart = Color(red: 0.96, green: 0.42, blue: 0.47)
    static let green = Color(red: 0.20, green: 0.80, blue: 0.45)

    // Metrics — radii match boring.notch's opened notch (top 19 / bottom 24).
    static let panelPaddingH: CGFloat = 18
    static let panelPaddingBottom: CGFloat = 16
    static let posterWidth: CGFloat = 60
    static let posterRadius: CGFloat = 6
    static let bottomCorner: CGFloat = 24
    static let topCorner: CGFloat = 19

    // Panel lift (boring.notch: black .7, radius 6, only when open).
    static let panelShadow = Color.black.opacity(0.7)
    static let panelShadowRadius: CGFloat = 6

    // Springs (boring.notch).
    static let openSpring = Animation.spring(response: 0.42, dampingFraction: 0.8)
    static let closeSpring = Animation.spring(response: 0.45, dampingFraction: 1.0)
    static let interactiveSpring = Animation.interactiveSpring(response: 0.38, dampingFraction: 0.8)
    static let contentSwap = Animation.smooth(duration: 0.35)

    /// GitHub-style contribution intensity (0 empty … 4 busiest), muted green.
    static func heatColor(level: Int) -> Color {
        switch max(0, min(4, level)) {
        case 0: return Color.white.opacity(0.06)
        case 1: return green.opacity(0.32)
        case 2: return green.opacity(0.55)
        case 3: return green.opacity(0.78)
        default: return green
        }
    }
}

/// The expanded-notch silhouette: small concave "ears" at the top (so the panel
/// reads as flaring out from the menu bar) and large rounded bottom corners —
/// the Dynamic Island / boring.notch shape.
struct NotchShape: Shape {
    var topRadius: CGFloat = NotchStyle.topCorner
    var bottomRadius: CGFloat = NotchStyle.bottomCorner

    func path(in rect: CGRect) -> Path {
        let tr = min(topRadius, rect.height / 2)
        let br = min(bottomRadius, rect.height / 2)
        var path = Path()
        // Top-left concave ear
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + tr, y: rect.minY + tr),
            control: CGPoint(x: rect.minX + tr, y: rect.minY)
        )
        // Down the left edge
        path.addLine(to: CGPoint(x: rect.minX + tr, y: rect.maxY - br))
        // Bottom-left convex corner
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + tr + br, y: rect.maxY),
            control: CGPoint(x: rect.minX + tr, y: rect.maxY)
        )
        // Bottom edge
        path.addLine(to: CGPoint(x: rect.maxX - tr - br, y: rect.maxY))
        // Bottom-right convex corner
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - tr, y: rect.maxY - br),
            control: CGPoint(x: rect.maxX - tr, y: rect.maxY)
        )
        // Up the right edge
        path.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY + tr))
        // Top-right concave ear
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.maxX - tr, y: rect.minY)
        )
        path.closeSubpath()
        return path
    }
}
