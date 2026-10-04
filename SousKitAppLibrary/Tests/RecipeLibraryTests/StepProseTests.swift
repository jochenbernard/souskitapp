@testable import RecipeLibrary
import SousKit
import SwiftUI
import Testing

@Suite("Step prose")
struct StepProseTests {
    private let parser = SousParser()

    private func runs(_ source: String) -> [StepRun] {
        guard let step = parser.parseRecipe(source).value.steps.first else {
            return []
        }

        return StepProse.runs(of: step)
    }

    private func prose(_ source: String) -> String {
        runs(source).map(\.text).joined()
    }

    private func annotations(_ source: String) -> [String] {
        runs(source).filter(\.isAnnotation).map(\.text)
    }

    @Test("an ingredient reads as its amount and its name")
    func ingredientWithAmount() {
        #expect(prose("Whisk @{200 g} flour@ in.") == "Whisk 200 g flour in.")
    }

    @Test("an ingredient with no amount reads as its name")
    func ingredientWithoutAmount() {
        #expect(prose("Season with @parsley@.") == "Season with parsley.")
    }

    @Test("a flag is left out of the prose")
    func flaggedIngredient() {
        #expect(prose("Season with @salt@:staple.") == "Season with salt.")
    }

    @Test("cookware reads as its name")
    func cookware() {
        #expect(prose("Wipe a #crepe pan# clean.") == "Wipe a crepe pan clean.")
    }

    @Test("a timer reads as it was written")
    func timer() {
        #expect(prose("Braise it ~1 h 30 min~ until tender.") == "Braise it 1 h 30 min until tender.")
    }

    @Test("a reference reads as the group it names")
    func reference() {
        #expect(prose("Serve the >rouille> beside it.") == "Serve the rouille beside it.")
    }

    @Test("a reference consuming an amount reads with it")
    func referenceWithAmount() {
        #expect(prose("Fold in >{400 g} bechamel>.") == "Fold in 400 g bechamel.")
    }

    @Test("prose with no annotation is left as written")
    func plainProse() {
        #expect(prose("Bake @ 180C until golden.") == "Bake @ 180C until golden.")
    }

    @Test("an ingredient is an annotation, amount and all")
    func annotatedIngredient() {
        #expect(annotations("Whisk @{200 g} flour@ in.") == ["200 g flour"])
    }

    @Test("cookware is an annotation")
    func annotatedCookware() {
        #expect(annotations("Wipe a #crepe pan# clean.") == ["crepe pan"])
    }

    @Test("a timer is an annotation")
    func annotatedTimer() {
        #expect(annotations("Braise it ~3 h~ until tender.") == ["3 h"])
    }

    @Test("a reference is an annotation")
    func annotatedReference() {
        #expect(annotations("Serve the >rouille> beside it.") == ["rouille"])
    }

    @Test("a reference consuming an amount is an annotation with it")
    func annotatedReferenceWithAmount() {
        #expect(annotations("Fold in >{400 g} bechamel>.") == ["400 g bechamel"])
    }

    @Test("prose between the annotations is not an annotation")
    func plainRuns() {
        #expect(annotations("Bake it until it is golden.").isEmpty)
    }

    @Test("a step marks each of the things it reaches for")
    func annotatedRunsOfAStep() {
        let source = "Brown @{150 g} lardons@ in a #casserole# for ~5 min~ until the fat runs."

        #expect(annotations(source) == ["150 g lardons", "casserole", "5 min"])
    }

    @Test("a step wrapped over several lines reads as one run of prose")
    func wrappedStep() {
        let source = """
            Cut @{1.2 kg} beef@ into large cubes and pat them dry. Brown
            @{150 g} lardons@ in a #casserole# for ~5 min~ until the fat runs.
            """

        #expect(!prose(source).contains("\n"))
        #expect(prose(source).contains("dry. Brown 150 g lardons in a casserole"))
    }

    @Test("an annotation wrapped across a break still closes")
    func wrappedAnnotation() {
        let source = """
            Pour over @{750 ml} red
            wine@ and bring it to a simmer.
            """

        #expect(annotations(source) == ["750 ml red wine"])
    }

    @Test("a timer links to what the link gives it, and nothing else does")
    func timerLink() throws {
        let link = try #require(URL(string: "sous-timer://start"))
        let step = try #require(parser.parseRecipe("Brown @{150 g} lardons@ for ~5 min~.").value.steps.first)
        let prose = StepProse.attributedProse(
            of: step,
            annotationColor: .red,
            timerLink: { _ in link }
        )

        #expect(prose.runs.compactMap(\AttributedString.Runs.Run.link) == [link])
    }
}
