import SwiftUI
import MiseCore

/// The notch surface. Collapsed = a bare black notch; on hover the window grows
/// and this renders the expanded black panel (header + active panel) hanging
/// below the notch, in the Dynamic Island silhouette.
struct NotchRootView: View {
    @Environment(AppState.self) private var app
    @Environment(NotchViewModel.self) private var vm

    var body: some View {
        ZStack(alignment: .top) {
            if vm.isOpen {
                expanded
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.92, anchor: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
            } else {
                collapsed
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.spring(response: 0.36, dampingFraction: 0.84), value: vm.isOpen)
        .animation(.easeInOut(duration: 0.2), value: vm.panel)
    }

    // Collapsed: a black blob matching the notch (invisible over a real notch,
    // a faux pill on non-notch Macs).
    private var collapsed: some View {
        Rectangle()
            .fill(Color.black)
            .frame(width: vm.notchSize.width, height: vm.notchSize.height)
            .clipShape(.rect(bottomLeadingRadius: 8, bottomTrailingRadius: 8))
    }

    private var expanded: some View {
        VStack(spacing: 0) {
            // Strip level with the physical notch, kept black so the panel reads
            // as growing out of the notch.
            Color.clear.frame(height: max(0, vm.notchSize.height - 6))

            VStack(alignment: .leading, spacing: 14) {
                NotchHeader()
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .padding(.horizontal, NotchStyle.panelPaddingH)
            .padding(.top, 10)
            .padding(.bottom, NotchStyle.panelPaddingBottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(NotchShape().fill(Color.black))
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
        VStack(spacing: 7) {
            Image(systemName: "film.stack")
                .font(.system(size: 24, weight: .light))
                .foregroundStyle(NotchStyle.textTertiary)
            Text(app.currentHandle.isEmpty ? "Add your Letterboxd username" : "Syncing @\(app.currentHandle)…")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(NotchStyle.textSecondary)
            if app.currentHandle.isEmpty {
                Text("Click the name above to get started.")
                    .font(.system(size: 11))
                    .foregroundStyle(NotchStyle.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
