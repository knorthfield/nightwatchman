import Foundation
import Observation

/// The durations in the "Activate for Duration" menu, in seconds. "Indefinitely" is always in the list.
@MainActor
@Observable
final class ActivationDurations {
    nonisolated static let indefinite = 0
    nonisolated static let standardSeconds = [5, 10, 15, 30, 60, 120, 300].map { $0 * 60 }

    enum AddError: Error, Equatable {
        case notPositive
        case alreadyInList
    }

    @ObservationIgnored private let defaults: UserDefaults

    /// The timed durations, shortest first.
    private(set) var timed: [Int] {
        didSet { defaults.set(timed, forKey: Settings.durations) }
    }

    /// The duration of a click on the menu bar icon.
    private(set) var defaultDuration: Int {
        didSet { defaults.set(defaultDuration, forKey: Settings.defaultDuration) }
    }

    /// "Indefinitely", then the timed durations.
    var all: [Int] { [Self.indefinite] + timed }

    init(defaults: UserDefaults = .standard) {
        Settings.registerDefaults(in: defaults)
        self.defaults = defaults
        let timed = (defaults.array(forKey: Settings.durations) as? [Int] ?? Self.standardSeconds)
            .filter { $0 > 0 }
        self.timed = Set(timed).sorted()
        let storedDefault = defaults.integer(forKey: Settings.defaultDuration)
        defaultDuration = timed.contains(storedDefault) ? storedDefault : Self.indefinite
    }

    func add(_ seconds: Int) throws(AddError) {
        guard seconds > 0 else { throw .notPositive }
        guard !timed.contains(seconds) else { throw .alreadyInList }
        timed = (timed + [seconds]).sorted()
    }

    func remove(_ seconds: Int) {
        timed.removeAll { $0 == seconds }
        if defaultDuration == seconds { defaultDuration = Self.indefinite }
    }

    func setDefault(_ seconds: Int) {
        guard all.contains(seconds) else { return }
        defaultDuration = seconds
    }

    func reset() {
        timed = Self.standardSeconds
        defaultDuration = Self.indefinite
    }

    /// "Indefinitely", or for example "1 hour, 30 minutes".
    static func title(for seconds: Int) -> String {
        guard seconds != indefinite else { return "Indefinitely" }
        return Duration.seconds(seconds).formatted(.units(allowed: [.hours, .minutes, .seconds], width: .wide))
    }
}
