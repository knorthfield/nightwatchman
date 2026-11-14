import AppKit
import ServiceManagement

@main
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let shared = AppDelegate()

    static func main() {
        NSApplication.shared.delegate = shared
        NSApplication.shared.run()
    }

    private let watch = Watch()
    private let durations = ActivationDurations()
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // The unit tests run inside the app: do not add a login item or a menu bar icon.
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }
        LoginItem.enableOnFirstLaunch()
        // Lets the Mac sleep again if the app stopped while the watch was active.
        watch.deactivate()
        statusItemController = StatusItemController(watch: watch, durations: durations)
        if UserDefaults.standard.bool(forKey: Settings.activateOnLaunch) {
            watch.activate(for: durations.defaultDuration)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        watch.deactivate()
    }
}

enum LoginItem {
    static var isEnabled: Bool { SMAppService.mainApp.status == .enabled }

    static func set(_ isEnabled: Bool) {
        try? isEnabled ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
    }

    static func enableOnFirstLaunch() {
        let key = "didEnableLoginItem"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)
        set(true)
    }
}
