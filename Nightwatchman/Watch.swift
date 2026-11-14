import AppKit
import Observation

/// Keeps the Mac awake while it is active.
@MainActor
@Observable
final class Watch {
    /// The duration of the activation in progress, in seconds. Nil when the Mac can sleep.
    private(set) var activeDuration: Int?
    /// When a timed activation ends.
    private(set) var endDate: Date?

    var isActive: Bool { activeDuration != nil }

    @ObservationIgnored private var displaySleepAssertion = DisplaySleepAssertion()
    @ObservationIgnored private var timer: Timer?

    func activate(for seconds: Int) {
        deactivate()
        if !UserDefaults.standard.bool(forKey: Settings.allowDisplaySleep) {
            displaySleepAssertion.hold()
        }
        activeDuration = seconds
        guard seconds != ActivationDurations.indefinite else { return }
        endDate = Date(timeIntervalSinceNow: TimeInterval(seconds))
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(seconds), repeats: false) { [weak self] _ in
            Task { @MainActor in self?.timerDidEnd() }
        }
    }

    func deactivate() {
        timer?.invalidate()
        timer = nil
        endDate = nil
        activeDuration = nil
        displaySleepAssertion.release()
    }

    private func timerDidEnd() {
        deactivate()
        if UserDefaults.standard.bool(forKey: Settings.quitWhenTimerEnds) {
            NSApp.terminate(nil)
        }
    }

    /// For example "25 minutes remaining". Counts a started minute as a full minute.
    static func remainingTitle(until endDate: Date, now: Date = .now) -> String {
        let seconds = max(0, endDate.timeIntervalSince(now)).rounded(.up)
        let remaining = seconds < 60
            ? Duration.seconds(seconds).formatted(.units(allowed: [.seconds], width: .wide))
            : Duration.seconds((seconds / 60).rounded(.up) * 60).formatted(.units(allowed: [.hours, .minutes], width: .wide))
        return "\(remaining) remaining"
    }
}
