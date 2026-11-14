import Foundation
import Testing
@testable import Nightwatchman

@MainActor
struct WatchTests {
    @Test(arguments: [
        (59.2, "1 minute remaining"),
        (60.0, "1 minute remaining"),
        (60.5, "2 minutes remaining"),
        (1500.0, "25 minutes remaining"),
        (5400.0, "1 hour, 30 minutes remaining"),
        (30.0, "30 seconds remaining"),
        (-5.0, "0 seconds remaining"),
    ])
    func theRemainingTimeIsInWords(seconds: Double, title: String) {
        let now = Date(timeIntervalSinceReferenceDate: 0)
        #expect(Watch.remainingTitle(until: now.addingTimeInterval(seconds), now: now) == title)
    }
}
