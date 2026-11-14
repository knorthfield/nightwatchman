import Foundation
import IOKit.ps

/// The battery and Low Power Mode at one moment.
struct PowerState: Equatable {
    /// From 0 to 100. Nil on a Mac with no battery.
    var batteryLevel: Int?
    var isLowPowerModeOn: Bool

    static var current: PowerState {
        PowerState(batteryLevel: currentBatteryLevel, isLowPowerModeOn: ProcessInfo.processInfo.isLowPowerModeEnabled)
    }

    private static var currentBatteryLevel: Int? {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef] else { return nil }
        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any],
                  description[kIOPSTypeKey] as? String == kIOPSInternalBatteryType,
                  let capacity = description[kIOPSCurrentCapacityKey] as? Int,
                  let maximum = description[kIOPSMaxCapacityKey] as? Int, maximum > 0 else { continue }
            return capacity * 100 / maximum
        }
        return nil
    }
}

/// When the watch must stop to save the battery.
struct PowerCutOff: Equatable {
    var isBatteryCutOffEnabled: Bool
    var batteryCutOffLevel: Int
    var isLowPowerModeCutOffEnabled: Bool

    static var fromSettings: PowerCutOff {
        let defaults = UserDefaults.standard
        return PowerCutOff(
            isBatteryCutOffEnabled: defaults.bool(forKey: Settings.batteryCutOffEnabled),
            batteryCutOffLevel: defaults.integer(forKey: Settings.batteryCutOffLevel),
            isLowPowerModeCutOffEnabled: defaults.bool(forKey: Settings.lowPowerModeCutOffEnabled))
    }

    /// A cut-off does not apply if its condition was already true when the user started the watch,
    /// because then the user wants the watch in that condition.
    func mustDeactivate(now: PowerState, atActivation: PowerState) -> Bool {
        if isBatteryCutOffEnabled, isBatteryLow(now), !isBatteryLow(atActivation) { return true }
        if isLowPowerModeCutOffEnabled, now.isLowPowerModeOn, !atActivation.isLowPowerModeOn { return true }
        return false
    }

    private func isBatteryLow(_ state: PowerState) -> Bool {
        guard let level = state.batteryLevel else { return false }
        return level <= batteryCutOffLevel
    }
}
