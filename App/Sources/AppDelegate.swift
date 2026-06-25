import AppKit
import SwiftUI

extension Notification.Name {
    static let miseOpenNotch = Notification.Name("mise.openNotch")
}

/// Owns the notch window and drives expand/collapse from hover. Patterned on
/// NotchDrop (MIT): a borderless transparent window resized between the
/// collapsed notch rect and the expanded panel rect.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()
    let vm = NotchViewModel()

    private var window: NotchWindow?
    private var placement = NotchPlacement.resolve()
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var pendingClose = false
    private var forcedOpen = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        buildWindow()
        installMouseMonitors()

        NotificationCenter.default.addObserver(
            self, selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(openRequested),
            name: .miseOpenNotch, object: nil
        )

        Task {
            await appState.bootstrap()
            // Debug: pin the notch open for screenshots (no hover/permission needed).
            if ProcessInfo.processInfo.environment["MISE_FORCE_OPEN"] == "1" {
                if let name = ProcessInfo.processInfo.environment["MISE_PANEL"],
                   let panel = NotchViewModel.Panel(rawValue: name) {
                    vm.panel = panel
                }
                forcedOpen = true
                open()
            } else if appState.history == nil && appState.currentHandle.isEmpty {
                // First run: open and keep the welcome prompt visible.
                open()
            }
        }
    }

    @objc private func openRequested() { open() }

    // MARK: Window

    private func buildWindow() {
        placement = NotchPlacement.resolve()
        vm.notchSize = placement.notchSize

        let window = NotchWindow()
        let host = NSHostingView(
            rootView: NotchRootView()
                .environment(appState)
                .environment(vm)
        )
        host.autoresizingMask = [.width, .height]
        window.contentView = host
        window.setFrame(placement.collapsedFrame, display: true)
        window.orderFrontRegardless()
        self.window = window
    }

    @objc private func screensChanged() {
        placement = NotchPlacement.resolve()
        vm.notchSize = placement.notchSize
        let frame = vm.isOpen ? placement.expandedFrame(openedSize: vm.openedSize) : placement.collapsedFrame
        window?.setFrame(frame, display: true)
    }

    // MARK: Open / close

    private func open() {
        pendingClose = false
        // Grow the (transparent) window first so the panel has room, then let the
        // SwiftUI content animate in with boring.notch's open spring.
        window?.setFrame(placement.expandedFrame(openedSize: vm.openedSize), display: true)
        withAnimation(NotchStyle.openSpring) { vm.status = .opened }
        // First run: make the window key + active so the username field is typable.
        if appState.currentHandle.isEmpty {
            window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func close() {
        guard vm.isOpen else { return }
        if forcedOpen { return }
        // Stay open until the user has set a username (welcome prompt).
        if appState.currentHandle.isEmpty && appState.history == nil { return }
        // Don't collapse while the user is editing (window is key).
        if window?.isKeyWindow == true { return }
        // Critically-damped close (no bounce), then shrink once it settles.
        withAnimation(NotchStyle.closeSpring) { vm.status = .closed }
        pendingClose = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            guard let self, self.pendingClose, !self.vm.isOpen else { return }
            self.pendingClose = false
            self.window?.setFrame(self.placement.collapsedFrame, display: true)
        }
    }

    // MARK: Hover

    private func installMouseMonitors() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] _ in
            self?.handleMouse()
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.handleMouse()
            return event
        }
    }

    private func handleMouse() {
        let loc = NSEvent.mouseLocation
        if vm.isOpen {
            let opened = placement.expandedFrame(openedSize: vm.openedSize)
            if !opened.contains(loc) { close() }
        } else {
            // Slightly enlarge the trigger zone around the notch for easy hover.
            let trigger = placement.collapsedFrame.insetBy(dx: -16, dy: -6)
            if trigger.contains(loc) { open() }
        }
    }
}
