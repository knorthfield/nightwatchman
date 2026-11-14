import AppKit
import Observation

/// The menu bar icon. A click turns the watch on or off. A right-click, or a click with Option or
/// Control, opens the menu.
@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let menu = NSMenu()
    private let watch: Watch
    private let durations: ActivationDurations
    private lazy var settingsWindow = SettingsWindow(durations: durations)

    init(watch: Watch, durations: ActivationDurations) {
        self.watch = watch
        self.durations = durations
        super.init()
        menu.delegate = self
        statusItem.button?.target = self
        statusItem.button?.action = #selector(iconWasClicked)
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        showWatchState()
    }

    private func showWatchState() {
        withObservationTracking {
            let isActive = watch.isActive
            statusItem.button?.image = NSImage(
                systemSymbolName: isActive ? "flashlight.on.fill" : "flashlight.off.fill",
                accessibilityDescription: isActive ? "Nightwatchman, on" : "Nightwatchman, off")
            statusItem.button?.toolTip = isActive
                ? "Click to let the Mac sleep.\nRight-click to show the menu."
                : "Click to keep the Mac awake.\nRight-click to show the menu."
        } onChange: { [weak self] in
            Task { @MainActor in self?.showWatchState() }
        }
    }

    @objc private func iconWasClicked() {
        let event = NSApp.currentEvent
        let wantsMenu = event?.type == .rightMouseUp
            || event?.modifierFlags.isDisjoint(with: [.option, .control]) == false
        if wantsMenu {
            // The menu is on the status item only for this click, so that a plain click does not open it.
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else if watch.isActive {
            watch.deactivate()
        } else {
            watch.activate(for: durations.defaultDuration)
        }
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        if let endDate = watch.endDate {
            menu.addItem(withTitle: Watch.remainingTitle(until: endDate), action: nil, keyEquivalent: "")
            menu.addItem(.separator())
        }

        let durationsItem = menu.addItem(withTitle: "Activate for Duration", action: nil, keyEquivalent: "")
        durationsItem.image = NSImage(systemSymbolName: "timer", accessibilityDescription: nil)
        let durationsMenu = NSMenu()
        for seconds in durations.all {
            let isDefault = seconds == durations.defaultDuration
            let item = durationsMenu.addItem(
                withTitle: ActivationDurations.title(for: seconds) + (isDefault ? " (Default)" : ""),
                action: #selector(durationWasChosen), keyEquivalent: "")
            item.target = self
            item.tag = seconds
            item.state = watch.activeDuration == seconds ? .on : .off
        }
        durationsItem.submenu = durationsMenu

        menu.addItem(.separator())
        let settingsItem = menu.addItem(withTitle: "Settings…", action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        settingsItem.image = NSImage(systemSymbolName: "gear", accessibilityDescription: nil)
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Nightwatchman", action: #selector(NSApplication.terminate), keyEquivalent: "q")
    }

    @objc private func showSettings() {
        settingsWindow.show()
    }

    @objc private func durationWasChosen(_ item: NSMenuItem) {
        watch.activate(for: item.tag)
    }
}
