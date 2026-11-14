import Foundation
import Testing
@testable import Nightwatchman

struct AppTests {
    @Test func theAppIsAMenuBarApp() {
        #expect(Bundle.main.object(forInfoDictionaryKey: "LSUIElement") as? Bool == true)
    }
}
