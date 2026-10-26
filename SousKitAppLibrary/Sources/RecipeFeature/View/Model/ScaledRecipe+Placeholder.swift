import SousKit

extension ScaledRecipe {
    /// The example quiche, which the screen draws as placeholders while the recipe it opens is read.
    ///
    /// - Parameter parser: What the recipe is read with.
    /// - Returns: The recipe, at the scale its file writes it in.
    static func placeholder(parser: SousParser) -> ScaledRecipe {
        // Never shown, since it is drawn as placeholders: it only gives the screen its sections and the bars their
        // lengths.
        let recipe = parser.parseRecipe(
            """
            ---
            title: Quiche Lorraine
            servings: 6
            prep-time: 30 min
            cook-time: 50 min
            tags: [lunch, classic, french]
            allergens: [gluten, dairy, eggs]
            ---

            ## Pastry
            Rub @{125 g} butter@ into @{250 g} flour@ with @{1/2 tsp} salt@:staple in a
            #mixing bowl# until it looks like breadcrumbs, bind it with @{3 tbsp} water@, and
            rest the dough in the fridge for ~30 min~.

            ## Filling
            Fry @{200 g} lardons@ in a #frying pan# over medium heat for ~5-6 min~ until the
            fat runs, drain them, and stir them through @{4} eggs@ beaten with
            @{300 ml} cream@, @{1/4 tsp} nutmeg@, and @black pepper@:staple.

            ## Assemble
            Roll the >pastry> out and line a 24 cm #tart tin#. Cover it with @parchment@:non-food,
            fill it with @{500 g} baking beans@:non-food, and bake it blind at 190C for ~15 min~.
            Lift them out, pour in the >filling>, scatter over @{50 g} gruyere@?, and bake at
            180C for ~35 min~ until just set.
            """
        )
        .value

        return ScaledRecipe(asWritten: recipe, parser: parser)
    }
}
