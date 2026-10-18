@testable import CookingFeature
import Testing

@Suite("New timer entry")
struct NewTimerEntryTests {
    @Test("an entry starts out with nothing typed, reading all zeros and running no timer")
    func startsEmpty() {
        let entry = NewTimerEntry()

        #expect(entry.digits.isEmpty)
        #expect(entry.clockDigits == "000000")
        #expect(entry.duration == nil)
    }

    @Test(
        "digits fill the seconds, then the minutes, then the hours from the right",
        arguments: [
            ("5", "000005", Duration.seconds(5)),
            ("45", "000045", Duration.seconds(45)),
            ("520", "000520", Duration.seconds(320)),
            ("1000", "001000", Duration.seconds(600)),
            ("13000", "013000", Duration.seconds(5_400)),
            ("130000", "130000", Duration.seconds(46_800))
        ]
    )
    func fillsFromTheRight(digits: String, clockDigits: String, duration: Duration) {
        let entry = NewTimerEntry(digits: digits)

        #expect(entry.clockDigits == clockDigits)
        #expect(entry.duration == duration)
    }

    @Test(
        "a pair past 59 counts in full",
        arguments: [
            ("90", Duration.seconds(90)),
            ("9000", Duration.seconds(5_400)),
            ("999999", Duration.seconds(362_439))
        ]
    )
    func overflowingPairs(digits: String, duration: Duration) {
        #expect(NewTimerEntry(digits: digits).duration == duration)
    }
}
