@testable import RecipeScaling
import Testing

@Suite("Scale target")
struct ScaleTargetTests {
    @Test("a step of servings is one serving, and of the multiplier half the recipe")
    func steps() {
        #expect(ScaleTarget.servings.stepped(6.0, by: 1.0, declared: 6.0) == 7.0)
        #expect(ScaleTarget.servings.stepped(6.0, by: -1.0, declared: 6.0) == 5.0)
        #expect(ScaleTarget.multiplier.stepped(1.0, by: 1.0, declared: 1.0) == 1.5)
        #expect(ScaleTarget.multiplier.stepped(1.0, by: -1.0, declared: 1.0) == 0.5)
    }

    @Test(
        "a yield steps by a round share of what the recipe declares",
        arguments: [
            (declared: 1.8, step: 0.1),
            (declared: 4.5, step: 0.2),
            (declared: 12.0, step: 1.0),
            (declared: 125.0, step: 10.0),
            (declared: 500.0, step: 50.0),
            (declared: 0.5, step: 0.05)
        ]
    )
    func yieldSteps(_ yield: (declared: Double, step: Double)) {
        #expect(abs(ScaleTarget.yield(unit: "kg").step(declared: yield.declared) - yield.step) < 1e-9)
    }

    @Test("a yield declared as a whole number of things steps by one of them", arguments: [1.0, 2.0, 6.0])
    func wholeYieldSteps(_ declared: Double) {
        #expect(ScaleTarget.yield(unit: "loaf").step(declared: declared) == 1.0)
    }

    @Test("stepping stops where a recipe stops making sense")
    func steppingStaysInRange() {
        #expect(ScaleTarget.servings.stepped(1.0, by: -1.0, declared: 6.0) == 1.0)
        #expect(ScaleTarget.multiplier.stepped(0.5, by: -1.0, declared: 1.0) == 0.5)
        #expect(ScaleTarget.multiplier.stepped(99.0, by: 1.0, declared: 1.0) == 99.0)
        #expect(ScaleTarget.yield(unit: "kg").stepped(0.1, by: -1.0, declared: 1.8) == 0.1)
    }

    @Test("a number typed past the range is not stepped back into it the wrong way")
    func steppingFromBeyondTheRange() {
        #expect(ScaleTarget.multiplier.stepped(0.25, by: -1.0, declared: 1.0) == 0.25)
        #expect(ScaleTarget.servings.stepped(1_200.0, by: 1.0, declared: 6.0) == 1_200.0)
    }

    @Test("a step from a typed number lands beside it")
    func steppingFromATypedNumber() {
        #expect(ScaleTarget.servings.stepped(7.5, by: 1.0, declared: 6.0) == 8.5)
        #expect(ScaleTarget.multiplier.stepped(0.75, by: 1.0, declared: 1.0) == 1.25)
    }
}
