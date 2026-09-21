@testable import RecipeFeature
import SousKit
import Testing

@Suite("Scaled recipe")
struct ScaledRecipeTests {
    private let parser = SousParser()

    private let crepes = """
        ---
        title: Crepes
        servings: 4
        yield: [12 crepes]
        ---

        Whisk @{4} eggs@ into @{250 g} flour@ with @{1/2 tsp} salt@ and @{=10 g} sugar@.
        """

    private let gratin = """
        ---
        title: Gratin Dauphinois
        yield: [1.8 kg]
        ---

        Peel @{1.2 kg} potatoes@ and simmer them in @{500 ml} cream@.
        """

    private let vinaigrette = """
        ---
        title: Vinaigrette
        ---

        Whisk @{1 tsp} dijon mustard@ into @{2 tbsp} red wine vinegar@.
        """

    private func recipe(_ source: String) -> Recipe {
        parser.parseRecipe(source).value
    }

    private func amounts(of recipe: Recipe) -> [String?] {
        recipe.ingredients.map(\.amount?.text)
    }

    @Test("a recipe opens on the servings it declares, as written")
    func asWrittenWithDeclaredServings() {
        let scaled = ScaledRecipe(asWritten: recipe(crepes))

        #expect(scaled.scale == RecipeScale(target: .servings, value: 4.0))
        #expect(scaled.isDefault)
        #expect(scaled.scaled == scaled.asWritten)
        #expect(amounts(of: scaled.scaled) == ["4", "250 g", "1/2 tsp", "10 g"])
    }

    @Test("a recipe declaring no servings opens on the multiplier")
    func asWrittenWithoutDeclaredServings() {
        let scaled = ScaledRecipe(asWritten: recipe(vinaigrette))

        #expect(scaled.scale == RecipeScale(target: .multiplier, value: 1.0))
        #expect(scaled.isDefault)
    }

    @Test("the targets are the servings, then the yields, then the multiplier every recipe has")
    func targets() {
        #expect(
            ScaledRecipe(asWritten: recipe(crepes)).targets
                == [.servings, .yield(unit: "crepes"), .multiplier]
        )
        #expect(ScaledRecipe(asWritten: recipe(vinaigrette)).targets == [.multiplier])
    }

    @Test("a recipe declaring a yield and no servings opens on the yield")
    func asWrittenWithOnlyAYield() {
        let scaled = ScaledRecipe(asWritten: recipe(gratin))

        #expect(scaled.scale == RecipeScale(target: .yield(unit: "kg"), value: 1.8))
        #expect(scaled.isDefault)
    }

    @Test("a yield takes the recipe to it, and the servings along with it")
    func scalingToAYield() {
        let scale = RecipeScale(target: .yield(unit: "crepes"), value: 18.0)
        let scaled = ScaledRecipe(asWritten: recipe(crepes), scale: scale)

        #expect(scaled.scaled.metadata.yields.map(\.text) == ["18 crepes"])
        #expect(scaled.scaled.metadata.servings == 6.0)
        #expect(amounts(of: scaled.scaled) == ["6", "375 g", "0.75 tsp", "10 g"])
    }

    @Test("a yield is restated as asked for, where multiplying would land just off it")
    func yieldRestatedExactly() {
        let scale = RecipeScale(target: .yield(unit: "kg"), value: 2.5)
        let scaled = ScaledRecipe(asWritten: recipe(gratin), scale: scale)

        #expect(scaled.scaled.metadata.yields.map(\.text) == ["2.5 kg"])
    }

    @Test("what the header declares of a yield is what that yield counts from")
    func declaredYield() {
        let scaled = ScaledRecipe(asWritten: recipe(crepes))

        #expect(scaled.declared(of: .yield(unit: "crepes")) == 12.0)
        #expect(scaled.value(of: .yield(unit: "crepes")) == 12.0)
        #expect(scaled.declared(of: .yield(unit: "kg")) == nil)
    }

    @Test(
        "a yield SousKit cannot scale toward is not offered",
        arguments: ["[2-3 loaves]", "[a jar]", "[12]", "[1 l, 2 l]"]
    )
    func yieldsLeftOut(_ yields: String) {
        let source = """
            ---
            title: Vinaigrette
            yield: \(yields)
            ---

            Whisk @{1 tsp} dijon mustard@.
            """

        #expect(ScaledRecipe(asWritten: recipe(source)).targets == [.multiplier])
    }

    @Test("a yield in servings is left to the servings the header already declares")
    func yieldInServings() {
        let source = """
            ---
            title: Crepes
            servings: 4
            yield: [4 servings, 12 crepes]
            ---

            Whisk @{4} eggs@.
            """

        #expect(ScaledRecipe(asWritten: recipe(source)).targets == [.servings, .yield(unit: "crepes"), .multiplier])
    }

    @Test("a step of a yield is a round share of it")
    func steppingAYield() {
        let scaled = ScaledRecipe(asWritten: recipe(gratin))

        #expect(scaled.stepped(by: 1.0) == RecipeScale(target: .yield(unit: "kg"), value: 1.9))
    }

    @Test("a multiplier multiplies what the recipe takes, and leaves a fixed amount alone")
    func scalingByAMultiplier() {
        let scale = RecipeScale(target: .multiplier, value: 2.0)
        let scaled = ScaledRecipe(asWritten: recipe(crepes), scale: scale)

        #expect(amounts(of: scaled.scaled) == ["8", "500 g", "1 tsp", "10 g"])
        #expect(!scaled.isDefault)
    }

    @Test("servings take the recipe to them, and restate what it yields")
    func scalingToServings() {
        let scale = RecipeScale(target: .servings, value: 6.0)
        let scaled = ScaledRecipe(asWritten: recipe(crepes), scale: scale)

        #expect(scaled.scaled.metadata.servings == 6.0)
        #expect(scaled.scaled.metadata.yields.map(\.text) == ["18 crepes"])
        #expect(amounts(of: scaled.scaled) == ["6", "375 g", "0.75 tsp", "10 g"])
    }

    @Test("the servings a recipe declares are what a scale counts from")
    func declared() {
        let scaled = ScaledRecipe(asWritten: recipe(crepes))

        #expect(scaled.declared(of: .servings) == 4.0)
        #expect(scaled.declared(of: .multiplier) == 1.0)
        #expect(ScaledRecipe(asWritten: recipe(vinaigrette)).declared(of: .servings) == nil)
    }

    @Test("what one target stands at is what the others follow from")
    func valuesOfTheOtherTargets() {
        let scale = RecipeScale(target: .servings, value: 6.0)
        let scaled = ScaledRecipe(asWritten: recipe(crepes), scale: scale)

        #expect(scaled.value(of: .multiplier) == 1.5)
        #expect(scaled.value(of: .servings) == 6.0)
        #expect(ScaledRecipe(asWritten: recipe(vinaigrette)).value(of: .servings) == nil)
    }

    @Test("the default is the recipe as written, on the first of its targets")
    func defaultScale() {
        let scale = RecipeScale(target: .multiplier, value: 1.0)
        let scaled = ScaledRecipe(asWritten: recipe(crepes), scale: scale)

        // The same food as the default, counted another way, so there is still a way back.
        #expect(!scaled.isDefault)
        #expect(scaled.defaultScale == RecipeScale(target: .servings, value: 4.0))
        #expect(
            ScaledRecipe(asWritten: recipe(gratin)).defaultScale
                == RecipeScale(target: .yield(unit: "kg"), value: 1.8)
        )
        #expect(
            ScaledRecipe(asWritten: recipe(vinaigrette)).defaultScale
                == RecipeScale(target: .multiplier, value: 1.0)
        )
    }

    @Test("a recipe declaring no servings does not scale toward them")
    func scalingToServingsWithoutDeclaredServings() {
        let scale = RecipeScale(target: .servings, value: 4.0)

        #expect(ScaledRecipe(asWritten: recipe(vinaigrette), scale: scale).isDefault)
    }

    @Test("a recipe of nothing is not one to cook from", arguments: [0.0, -1.0, .infinity, .nan])
    func unusableMultipliers(_ value: Double) {
        let scale = RecipeScale(target: .multiplier, value: value)

        #expect(ScaledRecipe(asWritten: recipe(crepes), scale: scale).isDefault)
    }

    @Test("servings of nothing are none to cook for", arguments: [0.0, -1.0, .infinity, .nan])
    func unusableServings(_ value: Double) {
        let scale = RecipeScale(target: .servings, value: value)

        #expect(ScaledRecipe(asWritten: recipe(crepes), scale: scale).isDefault)
    }
}
