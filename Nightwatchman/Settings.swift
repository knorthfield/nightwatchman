import Foundation

/// The keys of the settings in UserDefaults, and their values before the user changes them.
enum Settings {
    static let activateOnLaunch = "activateOnLaunch"
    static let allowDisplaySleep = "allowDisplaySleep"
    static let quitWhenTimerEnds = "quitWhenTimerEnds"
    static let batteryCutOffEnabled = "batteryCutOffEnabled"
    static let batteryCutOffLevel = "batteryCutOffLevel"
    static let lowPowerModeCutOffEnabled = "lowPowerModeCutOffEnabled"
    static let durations = "durations"
    static let defaultDuration = "defaultDuration"

    static func registerDefaults(in defaults: UserDefaults = .standard) {
        defaults.register(defaults: [
            activateOnLaunch: false,
            allowDisplaySleep: false,
            quitWhenTimerEnds: false,
            // A closed Mac that stays awake in a bag gets hot, thus the cut-offs start on.
            batteryCutOffEnabled: true,
            batteryCutOffLevel: 20,
            lowPowerModeCutOffEnabled: true,
            durations: ActivationDurations.standardSeconds,
            defaultDuration: ActivationDurations.indefinite,
        ])
    }
}
