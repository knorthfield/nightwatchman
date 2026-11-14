import AppKit
import IOKit
import os

/// The `disablesleep` setting of pmset. While it is set, the Mac does not sleep, also with the lid
/// closed. Only root can change it, so a sudoers rule lets this user run the two pmset commands
/// without a password. The setting stays after a crash and after a restart, thus the app records
/// that it set the flag, and a watchdog process clears the flag if the app stops.
@MainActor
final class SleepDisabledFlag {
    static let sudoersPath = "/etc/sudoers.d/nightwatchman"
    private static let didSetKey = "didDisableSleep"
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Nightwatchman", category: "SleepDisabledFlag")

    private var watchdog: Process?

    /// What macOS reports. Another tool can also set the flag.
    static var isSet: Bool {
        let rootDomain = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPMrootDomain"))
        defer { IOObjectRelease(rootDomain) }
        let value = IORegistryEntryCreateCFProperty(rootDomain, "SleepDisabled" as CFString, kCFAllocatorDefault, 0)
        return value?.takeRetainedValue() as? Bool ?? false
    }

    /// Asks for an administrator the first time. Returns false if the Mac can still sleep.
    func set() -> Bool {
        guard Self.runPmset(disableSleep: true) || (Self.installSudoersRule() && Self.runPmset(disableSleep: true)) else {
            return false
        }
        UserDefaults.standard.set(true, forKey: Self.didSetKey)
        startWatchdog()
        return true
    }

    /// Does nothing if Nightwatchman did not set the flag.
    func clear() {
        guard UserDefaults.standard.bool(forKey: Self.didSetKey) else { return }
        watchdog?.terminate()
        watchdog = nil
        if Self.runPmset(disableSleep: false) {
            UserDefaults.standard.set(false, forKey: Self.didSetKey)
        }
    }

    private static func runPmset(disableSleep: Bool) -> Bool {
        let sudo = Process()
        sudo.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        sudo.arguments = ["-n", "/usr/bin/pmset", "-a", "disablesleep", disableSleep ? "1" : "0"]
        sudo.standardOutput = FileHandle.nullDevice
        sudo.standardError = FileHandle.nullDevice
        do {
            try sudo.run()
        } catch {
            logger.error("sudo did not start: \(error)")
            return false
        }
        sudo.waitUntilExit()
        return sudo.terminationStatus == 0
    }

    /// A shell that waits until this app is gone, then clears the flag. It continues after a crash
    /// or a force quit of the app.
    private func startWatchdog() {
        guard watchdog == nil else { return }
        let shell = Process()
        shell.executableURL = URL(fileURLWithPath: "/bin/sh")
        shell.arguments = ["-c", Self.watchdogScript(appProcessID: ProcessInfo.processInfo.processIdentifier)]
        shell.standardOutput = FileHandle.nullDevice
        shell.standardError = FileHandle.nullDevice
        do {
            try shell.run()
            watchdog = shell
        } catch {
            Self.logger.error("The watchdog did not start: \(error)")
        }
    }

    static func watchdogScript(appProcessID: Int32) -> String {
        "trap 'exit 0' TERM; while /bin/kill -0 \(appProcessID) 2>/dev/null; do /bin/sleep 2; done; "
            + "/usr/bin/sudo -n /usr/bin/pmset -a disablesleep 0"
    }

    /// The line in the sudoers file. Nil for a user name that is not safe to put in a shell command.
    static func sudoersRule(user: String) -> String? {
        let safeCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-")
        guard !user.isEmpty, user.unicodeScalars.allSatisfy(safeCharacters.contains) else { return nil }
        return "\(user) ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 0, /usr/bin/pmset -a disablesleep 1"
    }

    /// Shows the administrator prompt of macOS. The rule goes into the sudoers folder only if visudo accepts it.
    private static func installSudoersRule() -> Bool {
        guard let rule = sudoersRule(user: NSUserName()) else { return false }
        let shellScript = "set -e; f=$(/usr/bin/mktemp); trap 'rm -f $f' EXIT; echo '\(rule)' > $f; "
            + "/usr/sbin/visudo -cf $f > /dev/null; /usr/bin/install -m 0440 -o root -g wheel $f \(sudoersPath)"
        let prompt = "Nightwatchman keeps your Mac awake also when the lid is closed. For this, an administrator must permit it one time."
        let appleScript = NSAppleScript(source: "do shell script \"\(shellScript)\" with prompt \"\(prompt)\" with administrator privileges")
        NSApp.activate()
        var errorInfo: NSDictionary?
        appleScript?.executeAndReturnError(&errorInfo)
        if let errorInfo { logger.error("The sudoers rule was not installed: \(errorInfo)") }
        return errorInfo == nil
    }
}
