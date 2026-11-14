import Testing
@testable import Nightwatchman

@MainActor
struct SleepDisabledFlagTests {
    @Test func theSudoersRulePermitsOnlyTheTwoPmsetCommands() {
        #expect(SleepDisabledFlag.sudoersRule(user: "kris.north-field_2")
            == "kris.north-field_2 ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 0, /usr/bin/pmset -a disablesleep 1")
    }

    @Test(arguments: ["", "kris northfield", "kris'; rm -rf /; '", "ALL,kris", "kris\n%admin"])
    func aUserNameThatIsNotSafeGetsNoRule(user: String) {
        #expect(SleepDisabledFlag.sudoersRule(user: user) == nil)
    }
}
