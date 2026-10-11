@testable import RecipeFeature
import RecipeLibrary
import RecipeScaling
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

    private let gratinForSix = """
        ---
        title: Gratin Dauphinois
        servings: 6
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

    private func scaledRecipe(
        _ source: String,
        preferredScale: PreferredScale = .asWritten,
        scale: RecipeScale? = nil
    ) -> ScaledRecipe {
        ScaledRecipe(
            asWritten: parser.parseRecipe(source).value,
            parser: parser,
            preferredScale: preferredScale,
            scale: scale
        )
    }

    private func amounts(of recipe: Recipe) -> [String?] {
        recipe.ingredients.map(\.amount?.text)
    }

    @Test("a recipe opens on the servings it declares, as written")
    func asWrittenWithDeclaredServings() {
        let scaled = scaledRecipe(crepes)

        #expect(scaled.scale == RecipeScale(target: .servings, value: 4.0))
        #expect(scaled.isDefault)
        #expect(scaled.scaled == scaled.asWritten)
        #expect(amounts(of: scaled.scaled) == ["4", "250 g", "1/2 tsp", "10 g"])
    }

    @Test("a recipe declaring no servings opens on the multiplier")
    func asWrittenWithoutDeclaredServings() {
        let scaled = scaledRecipe(vinaigrette)

        #expect(scaled.scale == RecipeScale(target: .multiplier, value: 1.0))
        #expect(scaled.isDefault)
    }

    @Test("the targets are the servings, then the yields, then the multiplier every recipe has")
    func targets() {
        #expect(
            scaledRecipe(crepes).targets
                == [.servings, .yield(unit: "crepes"), .multiplier]
        )
        #expect(scaledRecipe(vinaigrette).targets == [.multiplier])
    }

    @Test("a recipe declaring a yield and no servings opens on the yield")
    func asWrittenWithOnlyAYield() {
        let scaled = scaledRecipe(gratin)

        #expect(scaled.scale == RecipeScale(target: .yield(unit: "kg"), value: 1.8))
        #expect(scaled.isDefault)
    }

    @Test(
        "servings or a yield take the recipe to them, and restate the other",
        arguments: [
            RecipeScale(target: .servings, value: 6.0),
            RecipeScale(target: .yield(unit: "crepes"), value: 18.0)
        ]
    )
    func scalingToADeclaredTarget(_ scale: RecipeScale) {
        let scaled = scaledRecipe(crepes, scale: scale)

        #expect(scaled.scaled.metadata.servings == 6.0)
        #expect(scaled.scaled.metadata.yields.map(\.text) == ["18 crepes"])
        #expect(amounts(of: scaled.scaled) == ["6", "375 g", "0.75 tsp", "10 g"])
    }

    @Test("a yield is restated as asked for, where multiplying would land just off it")
    func yieldRestatedExactly() {
        let scale = RecipeScale(target: .yield(unit: "kg"), value: 2.5)
        let scaled = scaledRecipe(gratin, scale: scale)

        #expect(scaled.scaled.metadata.yields.map(\.text) == ["2.5 kg"])
    }

    @Test("what the header declares of a yield is what that yield counts from")
    func declaredYield() {
        let scaled = scaledRecipe(crepes)

        #expect(scaled.declared(of: .yield(unit: "crepes")) == 12.0)
        #expect(scaled.value(of: .yield(unit: "crepes")) == 12.0)
        #expect(scaled.declared(of: .yield(unit: "kg")) == nil)
    }

    @Test("counting on another target and back lands where it started")
    func countingBack() {
        let scale = RecipeScale(target: .servings, value: 7.0)
        let scaled = scaledRecipe(gratinForSix, scale: scale)
        let counted = scaled.counted(by: .multiplier)?.counted(by: .servings)

        #expect(counted?.scale == scale)
        #expect(counted?.scaled == scaled.scaled)
    }

    @Test("a scale that does not divide evenly writes its amounts to three decimals")
    func unevenScale() {
        let scale = RecipeScale(target: .servings, value: 5.0)
        let scaled = scaledRecipe(gratinForSix, scale: scale)

        #expect(scaled.scaled.metadata.yields.map(\.text) == ["1.5 kg"])
        #expect(amounts(of: scaled.scaled) == ["1 kg", "416.667 ml"])
    }

    @Test("amounts written to three decimals still sum to the exact total")
    func summingRoundedAmounts() {
        let source = """
            ---
            title: Brioche
            servings: 6
            ---

            Rub @{100 g} butter@ into the flour, fold in @{100 g} butter@, and brush with @{100 g} butter@.
            """
        let scaled = scaledRecipe(source, scale: RecipeScale(target: .servings, value: 2.0))

        #expect(amounts(of: scaled.scaled) == ["33.333 g", "33.333 g", "33.333 g"])
        #expect(RecipeDisplay.ingredientList(of: scaled.scaled).rows.map(\.amount) == ["100 g"])
    }

    @Test("the header's other numbers are written to three decimals")
    func headerToThreeDecimals() {
        let scale = RecipeScale(target: .yield(unit: "kg"), value: 1.0)

        #expect(scaledRecipe(gratinForSix, scale: scale).scaled.metadata.servings == 3.333)
    }

    @Test("a step of a yield is a round share of it")
    func steppingAYield() {
        let scaled = scaledRecipe(gratin)

        #expect(scaled.stepped(by: 1.0) == RecipeScale(target: .yield(unit: "kg"), value: 1.9))
    }

    @Test("a multiplier multiplies what the recipe takes, and leaves a fixed amount alone")
    func scalingByAMultiplier() {
        let scale = RecipeScale(target: .multiplier, value: 2.0)
        let scaled = scaledRecipe(crepes, scale: scale)

        #expect(amounts(of: scaled.scaled) == ["8", "500 g", "1 tsp", "10 g"])
        #expect(!scaled.isDefault)
    }

    @Test("the servings a recipe declares are what a scale counts from")
    func declared() {
        let scaled = scaledRecipe(crepes)

        #expect(scaled.declared(of: .servings) == 4.0)
        #expect(scaled.declared(of: .multiplier) == 1.0)
        #expect(scaledRecipe(vinaigrette).declared(of: .servings) == nil)
    }

    @Test("what one target stands at is what the others follow from")
    func valuesOfTheOtherTargets() {
        let scale = RecipeScale(target: .servings, value: 6.0)
        let scaled = scaledRecipe(crepes, scale: scale)

        #expect(scaled.value(of: .multiplier) == 1.5)
        #expect(scaled.value(of: .servings) == 6.0)
        #expect(scaledRecipe(vinaigrette).value(of: .servings) == nil)
    }

    @Test("the default is the recipe as written, on the first of its targets")
    func defaultScale() {
        let scale = RecipeScale(target: .multiplier, value: 1.0)
        let scaled = scaledRecipe(crepes, scale: scale)

        // The same food as the default, counted another way, so there is still a way back.
        #expect(!scaled.isDefault)
        #expect(scaled.defaultScale == RecipeScale(target: .servings, value: 4.0))
        #expect(
            scaledRecipe(gratin).defaultScale
                == RecipeScale(target: .yield(unit: "kg"), value: 1.8)
        )
        #expect(
            scaledRecipe(vinaigrette).defaultScale
                == RecipeScale(target: .multiplier, value: 1.0)
        )
    }

    @Test("the default is the scale preferred, on a recipe that scales that way")
    func preferredDefaultScale() {
        #expect(
            scaledRecipe(crepes, preferredScale: .servings(2.0)).defaultScale
                == RecipeScale(target: .servings, value: 2.0)
        )
        #expect(
            scaledRecipe(gratin, preferredScale: .servings(2.0)).defaultScale
                == RecipeScale(target: .yield(unit: "kg"), value: 1.8)
        )
    }

    @Test("a multiple preferred is counted on the recipe's first target")
    func preferredMultiple() {
        #expect(
            scaledRecipe(crepes, preferredScale: .multiplier(2.0)).defaultScale
                == RecipeScale(target: .servings, value: 8.0)
        )
        #expect(
            scaledRecipe(gratin, preferredScale: .multiplier(2.0)).defaultScale
                == RecipeScale(target: .yield(unit: "kg"), value: 3.6)
        )
        #expect(
            scaledRecipe(vinaigrette, preferredScale: .multiplier(2.0)).defaultScale
                == RecipeScale(target: .multiplier, value: 2.0)
        )
        #expect(
            scaledRecipe(crepes, preferredScale: .asWritten).defaultScale
                == RecipeScale(target: .servings, value: 4.0)
        )
    }

    @Test("a recipe opens on the scale preferred, and leaves it for a scale given")
    func preferredScaleOpens() {
        let atPreferred = scaledRecipe(crepes, preferredScale: .servings(2.0))
        let written = RecipeScale(target: .servings, value: 4.0)
        let atWritten = scaledRecipe(
            crepes,
            preferredScale: .servings(2.0),
            scale: written
        )

        #expect(atPreferred.isDefault)
        #expect(amounts(of: atPreferred.scaled) == ["2", "125 g", "0.25 tsp", "10 g"])
        #expect(!atWritten.isDefault)
        #expect(atWritten.scaled == atWritten.asWritten)
    }

    @Test("a scale preferred that a recipe of nothing would follow leaves the recipe as written")
    func unusablePreferredScale() {
        #expect(scaledRecipe(crepes, preferredScale: .multiplier(0.0)).defaultScale.target == .servings)
    }

    @Test("a recipe declaring no servings does not scale toward them")
    func scalingToServingsWithoutDeclaredServings() {
        let scale = RecipeScale(target: .servings, value: 4.0)

        #expect(scaledRecipe(vinaigrette, scale: scale).isDefault)
    }

    @Test(
        "a recipe of nothing is not one to cook from",
        arguments: [ScaleTarget.multiplier, .servings],
        [0.0, -1.0, .infinity, .nan]
    )
    func unusableScales(_ target: ScaleTarget, _ value: Double) {
        let scale = RecipeScale(target: target, value: value)

        #expect(scaledRecipe(crepes, scale: scale).isDefault)
    }
}
