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

    @ObservationIgnored private let sleepDisabledFlag = SleepDisabledFlag()
    @ObservationIgnored private var displaySleepAssertion = DisplaySleepAssertion()
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var powerCheckTimer: Timer?
    @ObservationIgnored private var powerStateAtActivation = PowerState.current

    /// Also changes the duration of an activation in progress. Does nothing if the user refuses the
    /// administrator setup.
    func activate(for seconds: Int) {
        if !isActive {
            guard sleepDisabledFlag.set() else { return }
            startPowerChecks()
        }
        if UserDefaults.standard.bool(forKey: Settings.allowDisplaySleep) {
            displaySleepAssertion.release()
        } else {
            displaySleepAssertion.hold()
        }
        activeDuration = seconds
        timer?.invalidate()
        timer = nil
        endDate = nil
        guard seconds != ActivationDurations.indefinite else { return }
        endDate = Date(timeIntervalSinceNow: TimeInterval(seconds))
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(seconds), repeats: false) { [weak self] _ in
            Task { @MainActor in self?.timerDidEnd() }
        }
    }

    /// Also lets the Mac sleep again after the app stopped while the watch was active.
    func deactivate() {
        timer?.invalidate()
        timer = nil
        endDate = nil
        activeDuration = nil
        powerCheckTimer?.invalidate()
        powerCheckTimer = nil
        displaySleepAssertion.release()
        sleepDisabledFlag.clear()
    }

    /// The battery level changes slowly, thus a check each minute is sufficient.
    private func startPowerChecks() {
        powerStateAtActivation = .current
        powerCheckTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if PowerCutOff.fromSettings.mustDeactivate(now: .current, atActivation: self.powerStateAtActivation) {
                    self.deactivate()
                }
            }
        }
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
