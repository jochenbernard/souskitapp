import RecipeLibrary
import SousKit
import Testing

@Suite("Timer duration")
struct TimerDurationTests {
    private let parser = SousParser()

    private func duration(_ source: String) -> Duration? {
        let timer = parser.parseRecipe(source).value.steps.first?.segments.compactMap { segment in
            if case .timer(let timer) = segment {
                return timer
            }
            return nil
        }.first

        return timer.flatMap(TimerDuration.duration(of:))
    }

    @Test("a precise timer runs for its quantity")
    func precise() {
        #expect(duration("Rest the dough for ~30 min~.") == .seconds(1_800))
    }

    @Test("a range runs for its low end")
    func range() {
        #expect(duration("Fry the lardons for ~5-6 min~.") == .seconds(300))
    }

    @Test("a compound timer runs for the sum of its parts")
    func compound() {
        #expect(duration("Braise it ~1 h 30 min~ until tender.") == .seconds(5_400))
    }

    @Test("a timer in days runs for as many days")
    func days() {
        #expect(duration("Leave it for ~2 days~.") == .seconds(172_800))
    }

    @Test("a Dutch unit is read")
    func dutchUnit() {
        #expect(duration("Laat het ~1 uur~ rusten.") == .seconds(3_600))
    }

    @Test("a qualitative timer runs for no length of time")
    func qualitative() {
        #expect(duration("Chill it ~overnight~.") == nil)
    }

    @Test("a unit that is no length of time runs for none")
    func unknownUnit() {
        #expect(duration("Bake it for ~3 g~.") == nil)
    }
}
