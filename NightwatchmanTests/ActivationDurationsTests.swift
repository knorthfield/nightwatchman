import Foundation
import Testing
@testable import Nightwatchman

@MainActor
struct ActivationDurationsTests {
    private let defaults: UserDefaults
    private let durations: ActivationDurations

    init() {
        defaults = UserDefaults(suiteName: UUID().uuidString)!
        durations = ActivationDurations(defaults: defaults)
    }

    @Test func aNewInstallHasTheStandardDurationsAndDefaultsToIndefinitely() {
        #expect(durations.all == [0, 300, 600, 900, 1800, 3600, 7200, 18000])
        #expect(durations.defaultDuration == ActivationDurations.indefinite)
    }

    @Test func anAddedDurationGoesInOrderAndIsStored() throws {
        try durations.add(45 * 60)
        #expect(durations.timed == [300, 600, 900, 1800, 2700, 3600, 7200, 18000])
        #expect(ActivationDurations(defaults: defaults).timed == durations.timed)
    }

    @Test func aDurationThatIsInTheListIsRefused() {
        #expect(throws: ActivationDurations.AddError.alreadyInList) { try durations.add(300) }
    }

    @Test(arguments: [0, -60])
    func aDurationThatIsNotPositiveIsRefused(seconds: Int) {
        #expect(throws: ActivationDurations.AddError.notPositive) { try durations.add(seconds) }
    }

    @Test func theDefaultIsStored() {
        durations.setDefault(3600)
        #expect(ActivationDurations(defaults: defaults).defaultDuration == 3600)
    }

    @Test func aDurationThatIsNotInTheListCannotBeTheDefault() {
        durations.setDefault(42)
        #expect(durations.defaultDuration == ActivationDurations.indefinite)
    }

    @Test func removingTheDefaultDurationMakesIndefinitelyTheDefault() {
        durations.setDefault(3600)
        durations.remove(3600)
        #expect(!durations.timed.contains(3600))
        #expect(durations.defaultDuration == ActivationDurations.indefinite)
    }

    @Test func resetPutsBackTheStandardDurations() throws {
        try durations.add(42)
        durations.remove(300)
        durations.setDefault(600)
        durations.reset()
        #expect(durations.timed == ActivationDurations.standardSeconds)
        #expect(durations.defaultDuration == ActivationDurations.indefinite)
    }

    @Test(arguments: [(0, "Indefinitely"), (300, "5 minutes"), (3600, "1 hour"), (5430, "1 hour, 30 minutes, 30 seconds")])
    func titlesSayTheDurationInWords(seconds: Int, title: String) {
        #expect(ActivationDurations.title(for: seconds) == title)
    }
}
