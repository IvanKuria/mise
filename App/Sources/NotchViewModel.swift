import SwiftUI

/// UI state for the notch: open/closed, which panel is showing, and the
/// collapsed/expanded geometry. The `AppDelegate` owns the window and drives
/// open/close in response to hover; this is the shared observable state the
/// SwiftUI content reads.
@MainActor
@Observable
final class NotchViewModel {
    enum Status { case closed, opened }

    enum Panel: String, CaseIterable, Identifiable {
        case recent, onThisDay, heatmap
        var id: String { rawValue }
        var symbol: String {
            switch self {
            case .recent:    return "clock.fill"
            case .onThisDay: return "calendar"
            case .heatmap:   return "square.grid.3x3.fill"
            }
        }
        var title: String {
            switch self {
            case .recent:    return "Recent"
            case .onThisDay: return "On this day"
            case .heatmap:   return "Activity"
            }
        }
    }

    var status: Status = .closed
    var panel: Panel = .recent

    /// The collapsed notch size (real notch or faux pill), set at launch.
    var notchSize: CGSize = .zero
    /// The expanded panel size that hangs below the notch. Kept compact — just
    /// enough for one row of content; no wasted vertical space.
    let openedSize = CGSize(width: 680, height: 184)

    var isOpen: Bool { status == .opened }
}
