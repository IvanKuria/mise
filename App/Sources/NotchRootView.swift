import SwiftUI
import MiseCore

/// The notch surface. Collapsed = a bare black notch; on hover the window grows
/// and this renders the expanded black panel (header + active panel) hanging
/// below the notch.
struct NotchRootView: View {
    @Environment(AppState.self) private var app
    @Environment(NotchViewModel.self) private var vm

    var body: some View {
        ZStack(alignment: .top) {
            if vm.isOpen {
                expanded
                    .transition(.move(edge: .top).combined(with: .opacity))
            } else {
                collapsed
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.spring(response: 0.34, dampingFraction: 0.82), value: vm.isOpen)
    }

    // Collapsed: a black blob matching the notch (invisible over a real notch,
    // a faux pill on non-notch Macs).
    private var collapsed: some View {
        Rectangle()
            .fill(Color.black)
            .frame(width: vm.notchSize.width, height: vm.notchSize.height)
            .clipShape(.rect(bottomLeadingRadius: 10, bottomTrailingRadius: 10))
    }

    private var expanded: some View {
        VStack(spacing: 0) {
            // Top strip level with the physical notch (kept black so it merges).
            Color.clear.frame(height: max(0, vm.notchSize.height - 4))
            VStack(spacing: 10) {
                NotchHeader()
                Rectangle().fill(NotchStyle.hairline).frame(height: 1)
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            Color.black.clipShape(
                .rect(bottomLeadingRadius: NotchStyle.panelCornerRadius,
                      bottomTrailingRadius: NotchStyle.panelCornerRadius)
            )
        )
    }

    @ViewBuilder
    private var content: some View {
        if let history = app.history {
            switch vm.panel {
            case .recent:    RecentlyWatchedPanel(history: history)
            case .onThisDay: OnThisDayPanel(history: history)
            case .heatmap:   ContributionHeatmapPanel(history: history)
            }
        } else {
            emptyState
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "film.stack").font(.system(size: 22)).foregroundStyle(NotchStyle.textTertiary)
            Text(app.currentHandle.isEmpty ? "Set your Letterboxd username" : "Syncing \(app.currentHandle)…")
                .font(.system(size: 12)).foregroundStyle(NotchStyle.textSecondary)
            if app.currentHandle.isEmpty {
                Text("Click the name above to add one.")
                    .font(.system(size: 10)).foregroundStyle(NotchStyle.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
