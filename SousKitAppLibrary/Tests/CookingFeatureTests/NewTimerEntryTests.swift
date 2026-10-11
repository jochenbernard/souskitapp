@testable import CookingFeature
import Testing

@Suite("New timer entry")
struct NewTimerEntryTests {
    @Test("an entry starts out empty, counting minutes")
    func startsEmpty() {
        #expect(NewTimerEntry() == NewTimerEntry(text: "", unit: .minutes))
    }

    @Test(
        "a number runs for that many of its unit",
        arguments: [
            (NewTimerEntry(text: "45", unit: .seconds), Duration.seconds(45)),
            (NewTimerEntry(text: "8", unit: .minutes), Duration.seconds(480)),
            (NewTimerEntry(text: "2", unit: .hours), Duration.seconds(7_200)),
            (NewTimerEntry(text: "1.5", unit: .minutes), Duration.seconds(90)),
            (NewTimerEntry(text: "1,5", unit: .hours), Duration.seconds(5_400)),
            (NewTimerEntry(text: " 8 ", unit: .minutes), Duration.seconds(480))
        ]
    )
    func duration(entry: NewTimerEntry, duration: Duration) {
        #expect(entry.duration == duration)
    }

    @Test("a length is held to the second")
    func roundsToTheSecond() {
        #expect(NewTimerEntry(text: "0.51", unit: .minutes).duration == .seconds(31))
    }

    @Test("a second and a day are the shortest and the longest a timer runs")
    func limits() {
        #expect(NewTimerEntry(text: "1", unit: .seconds).duration == .seconds(1))
        #expect(NewTimerEntry(text: "24", unit: .hours).duration == .seconds(86_400))
        #expect(NewTimerEntry(text: "1440", unit: .minutes).duration == .seconds(86_400))
    }

    @Test(
        "a field holding no length from a second to a day runs no timer",
        arguments: [
            NewTimerEntry(text: "", unit: .minutes),
            NewTimerEntry(text: "0", unit: .minutes),
            NewTimerEntry(text: "0.4", unit: .seconds),
            NewTimerEntry(text: "-5", unit: .minutes),
            NewTimerEntry(text: "1.2.3", unit: .minutes),
            NewTimerEntry(text: "soon", unit: .minutes),
            NewTimerEntry(text: "nan", unit: .minutes),
            NewTimerEntry(text: "inf", unit: .seconds),
            NewTimerEntry(text: "1e400", unit: .hours),
            NewTimerEntry(text: "86401", unit: .seconds),
            NewTimerEntry(text: "1441", unit: .minutes),
            NewTimerEntry(text: "24.01", unit: .hours)
        ]
    )
    func noDuration(entry: NewTimerEntry) {
        #expect(entry.duration == nil)
    }

    @Test("the plus takes an empty field to one, and the minus leaves it empty")
    func steppingFromEmpty() {
        #expect(NewTimerEntry().stepped(by: 1.0) == NewTimerEntry(text: "1", unit: .minutes))
        #expect(NewTimerEntry().stepped(by: -1.0) == NewTimerEntry())
    }

    @Test("a step moves a whole number by one")
    func steppingAWholeNumber() {
        let entry = NewTimerEntry(text: "8", unit: .minutes)

        #expect(entry.stepped(by: 1.0) == NewTimerEntry(text: "9", unit: .minutes))
        #expect(entry.stepped(by: -1.0) == NewTimerEntry(text: "7", unit: .minutes))
    }

    @Test("a step takes a number with a fraction to the whole number that side of it")
    func steppingAFraction() {
        let entry = NewTimerEntry(text: "1,5", unit: .hours)

        #expect(entry.stepped(by: 1.0) == NewTimerEntry(text: "2", unit: .hours))
        #expect(entry.stepped(by: -1.0) == NewTimerEntry(text: "1", unit: .hours))
    }

    @Test("stepping stays between one and a day of the unit")
    func steppingStaysInRange() {
        #expect(NewTimerEntry(text: "1", unit: .seconds).stepped(by: -1.0) == NewTimerEntry(text: "1", unit: .seconds))
        #expect(NewTimerEntry(text: "24", unit: .hours).stepped(by: 1.0) == NewTimerEntry(text: "24", unit: .hours))
        #expect(
            NewTimerEntry(text: "1440", unit: .minutes).stepped(by: 1.0) == NewTimerEntry(text: "1440", unit: .minutes)
        )
    }

    @Test("a number typed past a day stays put under the plus, and comes back to a day under the minus")
    func steppingFromPastTheRange() {
        let entry = NewTimerEntry(text: "30", unit: .hours)

        #expect(entry.stepped(by: 1.0) == entry)
        #expect(entry.stepped(by: -1.0) == NewTimerEntry(text: "24", unit: .hours))
    }

    @Test("a number typed below one stays put under the minus, and comes up to one under the plus")
    func steppingFromBelowTheRange() {
        let entry = NewTimerEntry(text: "0.5", unit: .minutes)

        #expect(entry.stepped(by: -1.0) == entry)
        #expect(entry.stepped(by: 1.0) == NewTimerEntry(text: "1", unit: .minutes))
    }

    @Test("a field holding no number steps as an empty one does")
    func steppingFromNoNumber() {
        let entry = NewTimerEntry(text: "soon", unit: .minutes)

        #expect(entry.stepped(by: 1.0) == NewTimerEntry(text: "1", unit: .minutes))
        #expect(entry.stepped(by: -1.0) == entry)
    }
}
