import Testing
@testable import Nightwatchman

struct PowerCutOffTests {
    private let cutOff = PowerCutOff(isBatteryCutOffEnabled: true, batteryCutOffLevel: 20, isLowPowerModeCutOffEnabled: true)
    private let healthy = PowerState(batteryLevel: 80, isLowPowerModeOn: false)

    @Test func theWatchContinuesAboveTheBatteryLevel() {
        #expect(!cutOff.mustDeactivate(now: PowerState(batteryLevel: 21, isLowPowerModeOn: false), atActivation: healthy))
    }

    @Test func theWatchStopsAtTheBatteryLevel() {
        #expect(cutOff.mustDeactivate(now: PowerState(batteryLevel: 20, isLowPowerModeOn: false), atActivation: healthy))
    }

    @Test func theWatchStopsWhenLowPowerModeComesOn() {
        #expect(cutOff.mustDeactivate(now: PowerState(batteryLevel: 80, isLowPowerModeOn: true), atActivation: healthy))
    }

    @Test func aWatchThatStartedOnALowBatteryContinues() {
        let low = PowerState(batteryLevel: 15, isLowPowerModeOn: false)
        #expect(!cutOff.mustDeactivate(now: PowerState(batteryLevel: 10, isLowPowerModeOn: false), atActivation: low))
    }

    @Test func aWatchThatStartedInLowPowerModeContinues() {
        let lowPower = PowerState(batteryLevel: 80, isLowPowerModeOn: true)
        #expect(!cutOff.mustDeactivate(now: lowPower, atActivation: lowPower))
    }

    @Test func aWatchThatStartedInLowPowerModeStillStopsAtTheBatteryLevel() {
        let lowPower = PowerState(batteryLevel: 80, isLowPowerModeOn: true)
        #expect(cutOff.mustDeactivate(now: PowerState(batteryLevel: 20, isLowPowerModeOn: true), atActivation: lowPower))
    }

    @Test func aMacWithNoBatteryHasNoBatteryCutOff() {
        let noBattery = PowerState(batteryLevel: nil, isLowPowerModeOn: false)
        #expect(!cutOff.mustDeactivate(now: noBattery, atActivation: noBattery))
    }

    @Test func cutOffsThatAreOffDoNothing() {
        let off = PowerCutOff(isBatteryCutOffEnabled: false, batteryCutOffLevel: 20, isLowPowerModeCutOffEnabled: false)
        #expect(!off.mustDeactivate(now: PowerState(batteryLevel: 5, isLowPowerModeOn: true), atActivation: healthy))
    }
}
