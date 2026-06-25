import SwiftUI
import MiseCore

/// The notch surface. Collapsed = a bare black notch; on hover the window grows
/// and this renders the expanded black panel (header + active panel) hanging
/// below the notch, in the Dynamic Island silhouette.
struct NotchRootView: View {
    @Environment(AppState.self) private var app
    @Environment(NotchViewModel.self) private var vm
    @State private var welcomeDraft = ""
    @FocusState private var welcomeFocused: Bool

    var body: some View {
        ZStack(alignment: .top) {
            if vm.isOpen {
                expanded
                    .transition(.scale(scale: 0.8, anchor: .top).combined(with: .opacity))
            } else {
                collapsed
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(NotchStyle.contentSwap, value: vm.panel)
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

            VStack(alignment: .leading, spacing: 10) {
                NotchHeader()
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .padding(.horizontal, NotchStyle.panelPaddingH)
            .padding(.top, 7)
            .padding(.bottom, NotchStyle.panelPaddingBottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            NotchShape()
                .fill(Color.black)
                .shadow(color: NotchStyle.panelShadow, radius: NotchStyle.panelShadowRadius)
        )
        .overlay(alignment: .top) {
            // Seam: a thin black bar (inset past the concave ears) blends the
            // panel's top edge into the hardware notch, hiding the join line.
            Rectangle()
                .fill(Color.black)
                .frame(height: 2)
                .padding(.horizontal, NotchStyle.topCorner)
        }
    }

    @ViewBuilder
    private var content: some View {
        if let history = app.history {
            switch vm.panel {
            case .recent:    RecentlyWatchedPanel(history: history)
            case .onThisDay: OnThisDayPanel(history: history)
            case .heatmap:   ContributionHeatmapPanel(history: history)
            }
        } else if app.currentHandle.isEmpty {
            welcome
        } else {
            syncing
        }
    }

    // First run: enter a public Letterboxd username right here.
    private var welcome: some View {
        VStack(spacing: 10) {
            Image(systemName: "film.stack")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(NotchStyle.textSecondary)
            Text("Add your Letterboxd username")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(NotchStyle.textPrimary)
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Text("@").foregroundStyle(NotchStyle.textTertiary)
                    TextField("username", text: $welcomeDraft)
                        .textFieldStyle(.plain)
                        .foregroundStyle(NotchStyle.textPrimary)
                        .focused($welcomeFocused)
                        .onSubmit(submitWelcome)
                        .frame(width: 160)
                }
                .font(.system(size: 13, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Capsule().fill(NotchStyle.surface))

                Button(action: submitWelcome) {
                    Text("View")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(.white))
                }
                .buttonStyle(.plain)
                .disabled(welcomeDraft.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { welcomeFocused = true }
    }

    private func submitWelcome() {
        let value = welcomeDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        Task { await app.switchTo(handle: value) }
    }

    private var syncing: some View {
        VStack(spacing: 8) {
            ProgressView().controlSize(.small).tint(NotchStyle.textSecondary)
            Text("Syncing @\(app.currentHandle)…")
                .font(.system(size: 12))
                .foregroundStyle(NotchStyle.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
