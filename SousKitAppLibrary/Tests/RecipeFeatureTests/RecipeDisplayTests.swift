@testable import RecipeFeature
import SousKit
import Testing

@Suite("Recipe display")
struct RecipeDisplayTests {
    private let parser = SousParser()

    private func recipe(_ source: String) -> Recipe {
        parser.parseRecipe(source).value
    }

    private func runs(_ source: String) -> [StepRun] {
        guard let step = recipe(source).steps.first else {
            return []
        }

        return RecipeDisplay.runs(of: step)
    }

    private func prose(_ source: String) -> String {
        runs(source).map(\.text).joined()
    }

    private func underlined(_ source: String) -> [String] {
        runs(source).filter(\.isUnderlined).map(\.text)
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

    @Test("an ingredient is underlined, amount and all")
    func underlinedIngredient() {
        #expect(underlined("Whisk @{200 g} flour@ in.") == ["200 g flour"])
    }

    @Test("cookware is underlined")
    func underlinedCookware() {
        #expect(underlined("Wipe a #crepe pan# clean.") == ["crepe pan"])
    }

    @Test("a timer is underlined")
    func underlinedTimer() {
        #expect(underlined("Braise it ~3 h~ until tender.") == ["3 h"])
    }

    @Test("a reference is underlined")
    func underlinedReference() {
        #expect(underlined("Serve the >rouille> beside it.") == ["rouille"])
    }

    @Test("a reference consuming an amount is underlined with it")
    func underlinedReferenceWithAmount() {
        #expect(underlined("Fold in >{400 g} bechamel>.") == ["400 g bechamel"])
    }

    @Test("prose between the annotations is not underlined")
    func plainRuns() {
        #expect(underlined("Bake it until it is golden.").isEmpty)
    }

    @Test("a step underlines each of the things it reaches for")
    func underlinedRunsOfAStep() {
        let source = "Brown @{150 g} lardons@ in a #casserole# for ~5 min~ until the fat runs."

        #expect(underlined(source) == ["150 g lardons", "casserole", "5 min"])
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

        #expect(underlined(source) == ["750 ml red wine"])
    }

    @Test("the title is left out of the header rows, and a list joins onto one line")
    func metadataRows() {
        let source = """
            ---
            title: Crepes
            servings: 4
            tags: [dessert, french]
            ---

            Whisk it.
            """
        let rows = RecipeDisplay.metadataRows(of: recipe(source).metadata)

        #expect(rows.map(\.key) == ["servings", "tags"])
        #expect(rows.map(\.value) == ["4", "dessert, french"])
    }

    @Test("cookware reached for twice is named once")
    func cookwareNames() {
        let source = """
            Melt it in a #pan# and stir with a #spoon#.

            Return it to the #pan#.
            """

        #expect(RecipeDisplay.cookwareNames(of: recipe(source)) == ["pan", "spoon"])
    }

    @Test("step numbers run on across the groups")
    func stepNumbers() {
        let source = """
            ## Court-Bouillon
            Soften it.

            Simmer it.

            ## Rouille
            Pound it.
            """
        let parsed = recipe(source)

        #expect(RecipeDisplay.firstNumber(ofGroupAt: 0, in: parsed) == 1)
        #expect(RecipeDisplay.firstNumber(ofGroupAt: 1, in: parsed) == 3)
    }
}
