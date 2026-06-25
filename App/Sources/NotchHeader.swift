import SwiftUI
import MiseCore

/// The slim header of the expanded notch: avatar + username switcher (click to
/// change/add a profile), the active-panel switcher, and a sync button.
struct NotchHeader: View {
    @Environment(AppState.self) private var app
    @Environment(NotchViewModel.self) private var vm

    @State private var editing = false
    @State private var draft = ""
    @Namespace private var tabNS

    var body: some View {
        HStack(spacing: 10) {
            avatar
            handle
            Spacer(minLength: 12)
            panelSwitcher
            syncButton
        }
    }

    // MARK: Avatar

    private var avatar: some View {
        Group {
            if let url = app.history?.member.avatarURL {
                AsyncImage(url: url) { phase in
                    if let image = phase.image { image.resizable().aspectRatio(contentMode: .fill) }
                    else { avatarFallback }
                }
            } else {
                avatarFallback
            }
        }
        .frame(width: 24, height: 24)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(NotchStyle.hairline, lineWidth: 1))
    }

    private var avatarFallback: some View {
        ZStack {
            NotchStyle.surfaceElevated
            Image(systemName: "person.fill")
                .font(.system(size: 11))
                .foregroundStyle(NotchStyle.textTertiary)
        }
    }

    // MARK: Username switcher

    @ViewBuilder
    private var handle: some View {
        if editing {
            TextField("username", text: $draft)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(NotchStyle.textPrimary)
                .frame(width: 140)
                .onSubmit { commit() }
                .onExitCommand { editing = false }
        } else {
            Menu {
                if !app.recentHandles.isEmpty {
                    ForEach(app.recentHandles, id: \.self) { h in
                        Button("@\(h)") { Task { await app.switchTo(handle: h) } }
                    }
                    Divider()
                }
                Button("Change username…") { draft = app.currentHandle; editing = true }
            } label: {
                HStack(spacing: 4) {
                    Text(app.currentHandle.isEmpty ? "Set username" : "@\(app.currentHandle)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(app.currentHandle.isEmpty ? NotchStyle.textTertiary : NotchStyle.textPrimary)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(NotchStyle.textTertiary)
                }
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
        }
    }

    private func commit() {
        let value = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        editing = false
        guard !value.isEmpty else { return }
        Task { await app.switchTo(handle: value) }
    }

    // MARK: Panel switcher (segmented)

    private var panelSwitcher: some View {
        HStack(spacing: 0) {
            ForEach(NotchViewModel.Panel.allCases) { panel in
                let selected = vm.panel == panel
                Image(systemName: panel.symbol)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(selected ? NotchStyle.textPrimary : NotchStyle.textSecondary)
                    .frame(height: 26)
                    .padding(.horizontal, 13)
                    .background {
                        if selected {
                            Capsule(style: .continuous)
                                .fill(Color.white.opacity(0.15))
                                .matchedGeometryEffect(id: "tabpill", in: tabNS)
                        }
                    }
                    .contentShape(Capsule())
                    .onTapGesture { withAnimation(NotchStyle.contentSwap) { vm.panel = panel } }
                    .help(panel.title)
            }
        }
        .clipShape(Capsule(style: .continuous))
    }

    // MARK: Sync

    @ViewBuilder
    private var syncButton: some View {
        if app.isSyncing {
            ProgressView()
                .controlSize(.small)
                .tint(NotchStyle.textSecondary)
                .frame(width: 28, height: 28)
        } else {
            HoverButton(systemName: "arrow.clockwise") {
                Task { await app.syncNow() }
            }
            .disabled(app.currentHandle.isEmpty)
            .help("Sync now")
        }
    }
}
