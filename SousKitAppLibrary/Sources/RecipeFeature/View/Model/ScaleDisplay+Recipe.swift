import RecipeScaling

extension ScaleDisplay {
    /// What the sheet shows for a recipe, with the field holding what a cook has typed.
    ///
    /// - Parameters:
    ///   - recipe: The recipe at the scale in force.
    ///   - text: What the field holds.
    init(recipe: ScaledRecipe, text: String) {
        let declared = recipe.targets

        self.init(
            target: recipe.scale.target,
            text: text,
            // One target is no choice, so the chips are left off rather than offering it.
            targets: declared.count > 1 ? declared : [],
            follows: declared
                .filter({ $0 != recipe.scale.target })
                .compactMap { target in
                    recipe.value(of: target).map({ RecipeScale(target: target, value: $0) })
                },
            isDefault: recipe.isDefault
        )
    }
}
