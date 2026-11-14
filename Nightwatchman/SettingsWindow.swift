import AppKit
import SwiftUI

@MainActor
final class SettingsWindow {
    private let window: NSWindow

    init(durations: ActivationDurations) {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 600),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: true
        )
        window.title = "Nightwatchman Settings"
        window.isReleasedWhenClosed = false
        window.contentViewController = NSHostingController(rootView: SettingsView(durations: durations))
    }

    func show() {
        if !window.isVisible { window.center() }
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }
}
