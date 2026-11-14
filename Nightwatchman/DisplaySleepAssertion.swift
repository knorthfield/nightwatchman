import IOKit.pwr_mgt

/// Keeps the display on while it is held. macOS releases it if the app stops.
struct DisplaySleepAssertion {
    private var assertionID: IOPMAssertionID?

    mutating func hold() {
        guard assertionID == nil else { return }
        var newID = IOPMAssertionID(0)
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "Night Watchman keeps the Mac awake" as CFString,
            &newID)
        if result == kIOReturnSuccess { assertionID = newID }
    }

    mutating func release() {
        guard let assertionID else { return }
        IOPMAssertionRelease(assertionID)
        self.assertionID = nil
    }
}
