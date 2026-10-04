@testable import CookingFeature
import Foundation
import Testing

@Suite("Running timer")
struct RunningTimerTests {
    private let date = Date(timeIntervalSinceReferenceDate: 0.0)

    private func makeTimer(secondsLeft: TimeInterval, isRinging: Bool = false) -> RunningTimer {
        RunningTimer(
            id: UUID(),
            stepTimer: StepTimer(
                stepNumber: 3,
                text: "15 min",
                duration: .seconds(900)
            ),
            endDate: date.addingTimeInterval(secondsLeft),
            isRinging: isRinging
        )
    }

    @Test("a timer just started has none of its time run out")
    func justStarted() {
        #expect(makeTimer(secondsLeft: 900.0).fractionElapsed(at: date) == 0.0)
    }

    @Test("a timer part of the way through has that part run out")
    func partWay() {
        #expect(makeTimer(secondsLeft: 225.0).fractionElapsed(at: date) == 0.75)
    }

    @Test("a timer past its end has all of its time run out")
    func pastItsEnd() {
        #expect(makeTimer(secondsLeft: -10.0).fractionElapsed(at: date) == 1.0)
    }

    @Test("a ringing timer has all of its time run out")
    func ringing() {
        #expect(makeTimer(secondsLeft: 900.0, isRinging: true).fractionElapsed(at: date) == 1.0)
    }
}
