@testable import RecipeScaling
import Testing

@Suite("Scale number")
struct ScaleNumberTests {
    @Test("a whole number is written without a decimal point")
    func wholeNumbers() {
        #expect(ScaleNumber.text(12.0) == "12")
        #expect(ScaleNumber.text(1_200.0) == "1200")
    }

    @Test("a fraction is written in the recipe's notation, whatever the reader's")
    func recipeNotation() {
        #expect(ScaleNumber.text(1.5) == "1.5")
        #expect(ScaleNumber.text(3.625) == "3.625")
    }

    @Test("what is written reads back as the same number")
    func roundTrip() {
        for value in [0.5, 1.0, 1.5, 2.25, 12.0, 99.999] {
            #expect(ScaleNumber.value(of: ScaleNumber.text(value)) == value)
        }
    }

    @Test("a comma reads as a decimal point, as a decimal keypad offers it")
    func decimalSeparators() {
        #expect(ScaleNumber.value(of: "1,5") == 1.5)
        #expect(ScaleNumber.value(of: "1.5") == 1.5)
        #expect(ScaleNumber.value(of: " 3 ") == 3.0)
        #expect(ScaleNumber.value(of: "3\n") == 3.0)
    }

    @Test("a field holds no number until one is typed out", arguments: ["", " ", "-", ".", "half", "1x"])
    func unfinishedNumbers(_ text: String) {
        #expect(ScaleNumber.value(of: text) == nil)
    }

    @Test("nothing to cook is nothing to scale by", arguments: ["0", "-2", "0.0"])
    func unusableNumbers(_ text: String) {
        #expect(ScaleNumber.value(of: text) == nil)
    }
}
