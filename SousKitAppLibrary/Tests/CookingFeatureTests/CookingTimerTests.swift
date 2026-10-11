@testable import CookingFeature
import Testing

@Suite("Cooking timer")
struct CookingTimerTests {
    @Test("a step's timer reads as the step writes it")
    func stepTimerText() {
        #expect(CookingTimer.step(.stubbed()).text == "15 min")
    }

    @Test("a custom timer reads as its length, which English and Dutch abbreviate alike")
    func customTimerText() {
        #expect(CookingTimer.custom(.seconds(300)).text == "5 min")
        #expect(CookingTimer.custom(.seconds(45)).text == "45 sec")
    }

    @Test("a timer runs for its length in seconds, whatever started it")
    func seconds() {
        #expect(CookingTimer.step(.stubbed()).seconds == 900.0)
        #expect(CookingTimer.custom(.seconds(90)).seconds == 90.0)
    }
}
