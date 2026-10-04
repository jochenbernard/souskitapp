@testable import CookingFeature
import Foundation
import Testing

@Suite("Step timer link")
struct StepTimerLinkTests {
    @Test("a timer's link opens the same timer")
    func roundTrip() throws {
        let timer = StepTimer(
            stepNumber: 3,
            text: "15 min",
            duration: .seconds(900)
        )

        #expect(try StepTimer(link: #require(timer.link)) == timer)
    }

    @Test("any other link opens no timer")
    func otherLink() throws {
        #expect(try StepTimer(link: #require(URL(string: "https://example.com"))) == nil)
    }
}
